module monomer;

import std::math;
import std::io;

bool chainBlockRule = true;
double gapSize = 50;
int totalMonomerStates = 24;

struct MonomerTranslation {
  double x;
  double y;
}

enum MonomerTranslationDirection: int (MonomerTranslation t) {
  NONE = {0, 0}
}

fn MonomerTranslation getTranslation(int state) {
  if (state < 0) {
    state = (state + totalMonomerStates) % totalMonomerStates;
  } else {
    state = state % totalMonomerStates;
  }
  MonomerTranslation t = MonomerTranslationDirection.NONE.t;
  float targetAngle = (float) (2 * math::PI / (float) totalMonomerStates * (float) state);
  float y = math::sin(targetAngle);
  float x = math::cos(targetAngle);

  return MonomerTranslation { x * gapSize, y * gapSize };
}

struct MonomerPos {
  double x;
  double y;
}

fn bool MonomerPos.isSame(MonomerPos *self, MonomerPos *other) {
  return self.x == other.x && self.y == other.y;
}

fn double MonomerPos.dist(MonomerPos *self, MonomerPos *other) {
  return math::sqrt((self.x - other.x)*(self.x - other.x) + (self.y - other.y)*(self.y - other.y));
}

fn void MonomerPos.print(MonomerPos *self) {
  io::printf("%d %d\n", self.x, self.y);
}

struct Monomer {
  MonomerPos pos;
  int state;
}

fn Monomer* newMonomer(MonomerPos pos, int state) {
  return mem::new(Monomer, {pos, state});
}

fn void Monomer.print(Monomer *self) {
  io::printf("%d %d\n", self.pos.x, self.pos.y);
}

fn MonomerPos Monomer.getTranslatedPos(Monomer *self, int targetState = 0) {
  MonomerTranslation t = getTranslation(targetState);
  return MonomerPos {self.pos.x + t.x, self.pos.y + t.y };
}

fn MonomerPos Monomer.getInitialTranslatedPos(Monomer *self) {
  // initial pos is to the right
  return self.getTranslatedPos(0);
}

struct MonomerLink {
  Monomer *m;
  int translations;
  bool isBlocked;
  MonomerLink *prev;
  MonomerLink *next;
}

fn MonomerLink* newMonomerLink(MonomerLink* prev, Monomer* monomer, MonomerLink* next) {
  return mem::new(MonomerLink, {monomer, 0, false, prev, next});
}

fn bool MonomerLink.isTooNearPrevious(MonomerLink *self, MonomerPos *pos = null) {
  if(!pos) {
    return false;
  }

  if(!self.prev) {
    return false;
  }

  MonomerLink *p = self.prev;
  int i = 1;
  int maxPrevToCheck = (int) math::floor((double)totalMonomerStates * 0.8);
  //int maxPrevToCheck = 1000;
  pos.print();
  while(p && i < maxPrevToCheck) {
    double dist = pos.dist(&p.m.pos);
    p.m.print();
    io::printf("%f\n", dist);
    if (dist < gapSize/2+1) {
      return true;
    }
    p = p.prev;
    i += 1;
  }
  return false;
}

fn void MonomerLink.updateNextLinkPositions(MonomerLink *self, MonomerPos *newPos = null) {
  if(newPos) {
    self.m.pos = *newPos;
  }

  if(!self.next) {
    return;
  }

  MonomerPos nextStartingPos = self.m.getTranslatedPos(self.translations);
  self.next.updateNextLinkPositions(&nextStartingPos);
}

fn void MonomerLink.printConfiguration(MonomerLink *self) {
  int i = 1;
  MonomerLink *l = self;
  while(l.next) {
    io::printf("%d ", i);
    l.m.print();
    io::printf("%d ", i+1);
    l.next.m.print();
    l = l.next;
    i++;
  }
}

fn bool MonomerLink.turnNextLink(MonomerLink *self, int direction) {
  if(!self.next) {
    return true;
  }

  MonomerPos nextStartingPos = self.m.getTranslatedPos(self.translations + direction);
  if (chainBlockRule && self.next.isTooNearPrevious(&nextStartingPos)) {
    return false;
  }

  self.next.updateNextLinkPositions(&nextStartingPos);
  return true;
}

fn int MonomerLink.turnConfiguration(MonomerLink *self, bool turnByTurn = true) {
  if(!self.next) {
    return 0;
  }
  MonomerLink *l = self.next;

  int turnsRemaining = 0;
  bool alreadyTurnedOnce = false;
  while(l.next) {
    int s = l.m.state;
    if (l.isBlocked) {
      l = l.next;
      continue;
    }
    while(s && !alreadyTurnedOnce) {
      int translationDir = 1;
      if (s > 0) {
        translationDir = -1;
      }
      if (s < 0) {
        translationDir = 1;
      }
      bool nextIsNotBlocked = false;
      nextIsNotBlocked = l.turnNextLink(translationDir);
      if(!nextIsNotBlocked && s + translationDir == 0) {
        if (math::abs(l.translations) > 2 * totalMonomerStates) {
          l.isBlocked = true;
          s = 0;
        }
        l.translations += translationDir;
      } else {
        s += translationDir;
        l.translations += translationDir;
      }

      l.m.state = s;

      if(turnByTurn) {
        alreadyTurnedOnce = true;
      }
    }
    turnsRemaining += math::abs(s);
    l = l.next;
  }

  return turnsRemaining;
}

fn MonomerLink* initLink(int* monomerStates, int length, int initialX = 50, int initialY = 500) {
  Monomer *startMonomer = newMonomer(MonomerPos {initialX, initialY}, monomerStates[0]);
  MonomerLink *startLink = newMonomerLink(null, startMonomer, null);
  MonomerLink *currentLink = startLink;
  for(int i = 1; i < length; i++) {
    Monomer *m = newMonomer(currentLink.m.getInitialTranslatedPos(), monomerStates[i]);
    MonomerLink *l = newMonomerLink(currentLink, m, null);
    currentLink.next = l;
    currentLink = l;
  }
  return startLink;
}
