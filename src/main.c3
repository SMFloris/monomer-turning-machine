module snake_monomer;

import raylib5;
import extrarl;

import std::math;
import std::io;
import monomer;
import arguments;

int screenWidth = 1000;
int screenHeight = 1000;
int fps = 60;
int initialX = 100;
int initialY = 500;

double tk;

float timeToChange = 1;
int monomerLength = 5;
int modeMonomer = 1;
int modeInstant = -1;

math::random::SimpleRandom rng;

monomer::MonomerLink *monomerConfiguration;

fn void initMonomerConfiguration(bool random) {
  int *monomerStates = mem::new_array(int, monomerLength);
  for(int i=0; i < monomerLength; i++) {
    if (random) {
      if (i == 0) {
        monomerStates[i] = (math::abs(rng.next_int()) % (monomer::totalMonomerStates * 2 + 1)) - monomer::totalMonomerStates;
      } else {
        int maxDegreesEachTurn = (int) ((double) monomer::totalMonomerStates * 0.3);
        monomerStates[i] = monomerStates[i-1] + (math::abs(rng.next_int()) % (maxDegreesEachTurn * 2 + 1)) - maxDegreesEachTurn;
      }
    } else {
      monomerStates[i] = i;
    }
  }

  monomerConfiguration = monomer::initLink(monomerStates, monomerLength, initialX, initialY);
}

fn bool isKeyPressed(rl::KeyboardKey key) {
  return (rl::isKeyDown(key) && (rl::getTime() - tk > 0.1));
}

fn void resetKeyPressed() {
  tk = rl::getTime();
}

fn int main(String[] args)
{
  rl::setTraceLogLevel(rl::TraceLogLevel.NONE);

  int! monomers = arguments::getIntArgument(args, "--monomers");
  if(try monomers) {
    monomerLength = monomers;
  }

  String! seed = arguments::getStringArgument(args, "--seed");
  if(try seed) {
    rng.set_seed(seed);
  }

  bool randomGeneration = true;
  int! random = arguments::getIntArgument(args, "--random");
  if(try random) {
    randomGeneration = random > 0;
  }

  bool generateAndExit = false;
  String! programMode = arguments::getStringArgument(args, "--mode");
  if(try programMode) {
    generateAndExit = programMode == "generate";
  }

  initMonomerConfiguration(randomGeneration);
  if(generateAndExit) {
      monomerConfiguration.turnConfiguration(false);
      monomerConfiguration.printConfiguration();
      return 0;
  }

  double t0 = rl::getTime();
  tk = rl::getTime();
	rl::initWindow(screenWidth, screenHeight, "Raylib in C3!");

  rl::Camera2D camera;
  camera.target = rl::Vector2{ (int) monomerConfiguration.m.pos.x, (int) monomerConfiguration.m.pos.y };
  camera.offset = rl::Vector2{ screenWidth/2.0f, screenHeight/2.0f };
  camera.rotation = 0.0f;
  camera.zoom = 1.0f;

  rl::setTargetFPS(60);

	while (!rl::windowShouldClose())
	{
    if (isKeyPressed(rl::KEY_J)) {
      timeToChange -= 0.01;
      resetKeyPressed();
    } 
    else if (isKeyPressed(rl::KEY_K)) {
      timeToChange += 0.01;
      resetKeyPressed();
    } 
    if(timeToChange < 0.01) {
      timeToChange = 0.01;
    } else if (timeToChange > 1) {
      timeToChange = 1;
    }
    
    if(rl::isKeyDown(rl::KEY_LEFT)) {
      camera.target.x -= 5;
      resetKeyPressed();
    } else if (rl::isKeyDown(rl::KEY_RIGHT)) {
      camera.target.x += 5;
      resetKeyPressed();
    } else if (rl::isKeyDown(rl::KEY_UP)) {
      camera.target.y -= 5;
      resetKeyPressed();
    } else if (rl::isKeyDown(rl::KEY_DOWN)) {
      camera.target.y += 5;
      resetKeyPressed();
    }


    if (rl::isKeyReleased(rl::KEY_M)) {
      modeMonomer *= -1; 
    }

    if (rl::isKeyReleased(rl::KEY_S)) {
      modeInstant *= -1;
    } 

    if (rl::isKeyReleased(rl::KEY_R)) {
      initMonomerConfiguration(randomGeneration);
      resetKeyPressed();
    }

    if (isKeyPressed(rl::KEY_A)) {
      monomerLength -= 1;
      initMonomerConfiguration(randomGeneration);
      resetKeyPressed();
    } 
    else if (isKeyPressed(rl::KEY_D)) {
      monomerLength += 1;
      initMonomerConfiguration(randomGeneration);
      resetKeyPressed();
    }
    monomerLength = math::clamp(monomerLength, 3, 100);


    if(modeInstant > 0) {
      monomerConfiguration.turnConfiguration(false);
    } else if(rl::getTime() - t0 > timeToChange) {
      monomerConfiguration.turnConfiguration(true);
      t0 = rl::getTime();
    }
		rl::@drawing() {
			rl::clearBackground(rl::RAYWHITE);
      rl::drawText(rl::textFormat("Monomers: %d", monomerLength), 10, 10, 20, rl::BLACK);
      rl::drawText("a/d - increase/decrease number of monomers", 10, 40, 20, rl::LIGHTGRAY);
      rl::drawText("m - toggle between line / monomers mode", 10, 70, 20, rl::LIGHTGRAY);
      rl::drawText("r - redo", 10, 100, 20, rl::LIGHTGRAY);
      rl::drawText("s - toggle between step and instant solve", 10, 130, 20, rl::LIGHTGRAY);
      if(modeInstant > 0) {
        rl::drawText("MODE: instant", 10, 210, 20, rl::BLACK);
      } else {
        rl::drawText("j/k - increase/decrease time between changes", 10, 160, 20, rl::LIGHTGRAY);
        rl::drawText("MODE: step", 10, 190, 20, rl::BLACK);
        rl::drawText(rl::textFormat("Time between steps: %f", timeToChange), 10, 210, 20, rl::BLACK);
      }
      rl::beginMode2D(camera);
        if(modeMonomer > 0) {
          drawMonomerLinks(monomerConfiguration);
        } else {
          drawMonomerLines(monomerConfiguration);
        }
      rl::endMode2D();
    };
  }

	io::printn("Hello, World!");
	return 0;
}

fn void printMonomerLinks(MonomerLink *l) {
  MonomerLink *m = l;
  int i = 0;
  while (m != null) {
    io::printf("Monomer %d is %d \n",i, m.m.state);
    m = m.next;
    i++;
  }
}

fn void drawMonomerLines(MonomerLink *l) {
  MonomerLink *c = l;
  rl::Vector2 *v = mem::new_array(rl::Vector2, monomerLength);
  int i = 0;
  while(c != null) {
    v[i] = Vector2 { (int)c.m.pos.x, (int)c.m.pos.y };
    i += 1;
    c = c.next;
  }
  extrarl::drawSplineCatmullRom(v, monomerLength, 10, rl::RED);
}

fn void drawMonomerLinks(MonomerLink *l) {
  MonomerLink *c = l;
  while(c != null) {
    drawMonomerLink(c, c.next);
    drawMonomer(c.m);
    c = c.next;
  }
}

fn void drawMonomerLink(MonomerLink *start, MonomerLink *end) {
  if(start == null || end == null) {
    return;
  }

  rl::Color linkColor = rl::BLACK;
  if (end.isBlocked) {
    linkColor = rl::RED;
  }
  rl::drawLineEx({(int)start.m.pos.x, (int)start.m.pos.y}, {(int)end.m.pos.x, (int)end.m.pos.y}, 10, linkColor);
}

fn void drawMonomer(Monomer *m) {
    rl::Color monomerColor = rl::DARKBLUE;
    switch(math::abs(m.state) % 6) {
      case 0: monomerColor = rl::YELLOW;
      case 1: monomerColor = rl::GOLD;
      case 2: monomerColor = rl::ORANGE;
      case 3: monomerColor = rl::SKYBLUE;
      case 4: monomerColor = rl::BLUE;
      case 5: monomerColor = rl::DARKBLUE;
    }
    rl::drawCircle((int)m.pos.x, (int)m.pos.y, 15, monomerColor);
    rl::drawText(rl::textFormat(" %d ", m.state), (int)m.pos.x - 7, (int)m.pos.y - 7, 15, rl::BLACK);
}
