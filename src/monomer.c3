module monomer;

import std::math;
import std::io;

int gapSize = 50;

struct MonomerTranslation {
  int x;
  int y;
}

enum MonomerTranslationDirection: int (MonomerTranslation t) {
  RIGHT = {2, 0},
  RIGHT_UP = {1, -2},
  LEFT_UP = {-1, -2},
  LEFT = {-2, 0},
  LEFT_DOWN = {-1, 2},
  RIGHT_DOWN = {1, 2},
  NONE = {0, 0}
}

fn MonomerTranslation getTranslation(int state) {
  if (state < 0) {
    state = (state + 6) % 6;
  } else {
    state = state % 6;
  }
  MonomerTranslation t = MonomerTranslationDirection.NONE.t;
  switch(state) {
    case 0:  {
      t = MonomerTranslationDirection.RIGHT.t;
      break;
    }
    case 1: {
      t = MonomerTranslationDirection.RIGHT_UP.t;
      break;
    }
    case 2: {
      t = MonomerTranslationDirection.LEFT_UP.t;
      break;
    }
    case 3: {
      t = MonomerTranslationDirection.LEFT.t;
      break;
    }
    case 4: {
      t = MonomerTranslationDirection.LEFT_DOWN.t;
      break;
    }
    case 5: {
      t = MonomerTranslationDirection.RIGHT_DOWN.t;
      break;
    }
  }

  return MonomerTranslation { t.x * gapSize, t.y * gapSize };
}

struct MonomerPos {
  int x;
  int y;
}

struct Monomer {
  MonomerPos pos;
  int state;
}

fn Monomer* newMonomer(MonomerPos pos, int state) {
  return mem::new(Monomer, {pos, state});
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
  MonomerLink *prev;
  MonomerLink *next;
}

fn MonomerLink* newMonomerLink(MonomerLink* prev, Monomer* monomer, MonomerLink* next) {
  return mem::new(MonomerLink, {monomer, 0, prev, next});
}

fn void MonomerLink.updateLinkPositions(MonomerLink *self, MonomerPos *newPos = null) {
  if(newPos) {
    self.m.pos = *newPos;
  }

  if(!self.next) {
    return;
  }

  MonomerPos nextStartingPos = self.m.getTranslatedPos(self.translations);
  self.next.updateLinkPositions(&nextStartingPos);
}

fn void MonomerLink.bumpIfNextBlocksCurrent(MonomerLink *self) {
  if(!self.next) {
    return;
  }

  int tries = 0;
  while(
    (self.m.pos.x == self.next.m.pos.x && self.m.pos.y == self.next.m.pos.y)
    || (self.prev && self.prev.m.pos.x == self.next.m.pos.x && self.prev.m.pos.y == self.next.m.pos.y)
  ) {
    if(self.translations < 0) {
      self.translations -= 1;
    } else {
      self.translations += 1;
    }
    self.updateLinkPositions();
    tries += 1;
    if(tries == 3) {
      break;
    }
  }
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
    while(s && !alreadyTurnedOnce) {
      int translationDir = 1;
      if (s > 0) {
        s = s - 1;
        translationDir = 1;
      }
      if (s < 0) {
        s = s + 1;
        translationDir = -1;
      }
      l.translations += translationDir;
      l.m.state = s;

      if (turnByTurn) {
        l.updateLinkPositions();
        l.bumpIfNextBlocksCurrent();
        alreadyTurnedOnce = true;
        break;
      }
    }
    turnsRemaining += math::abs(s);
    if(turnByTurn && alreadyTurnedOnce) {
      break;
    }
    l.updateLinkPositions();
    l.bumpIfNextBlocksCurrent();
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
