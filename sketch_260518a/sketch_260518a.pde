import processing.sound.*;
SoundFile musicaDeFundo;

// Imagens globais para as folhas de sprites do jogador
PImage spriteIdle, spriteRun, spriteAttack, spriteJump;
PImage[] framesIdle, framesRun, framesAttack, framesJump;

// MODIFICADO: Novas imagens globais para as folhas de sprites do Lobo (Inimigo Vermelho)
PImage spriteWolfRun, spriteWolfAttack;
PImage[] framesWolfRun, framesWolfAttack;

ArrayList<Block> blocks = new ArrayList<Block>();
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Item> items = new ArrayList<Item>();
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Boss> bosses = new ArrayList<Boss>();
ArrayList<EnergyBall> energyBalls = new ArrayList<EnergyBall>(); 

Player player;

boolean left, right, jump, jumpPressed, atk, castBall;
int tile = 48;
int score = 0;
int level = 0;
float camX = 0;

final int MENU = 0;
final int PLAY = 1;
final int GAMEOVER = 2;
final int WIN = 3;
int screen = MENU;

String[][] maps = {
  {
    "................................................................",
    "................................................................",
    "..............o.......................g........................",
    "............#####...................#####......................",
    "................................................................",
    ".......o...................C............................o......",
    ".....#####...............#####.........................#####....",
    "..P..............o......................F....................N.",
    "#########......#####..............############........#########",
    "................................................................",
    ".......................H......................g.................",
    ".....................#####..................#####...............",
    "..........o.....................................................",
    "........#####..................#####...............#####........",
    "................................................................",
    "################.......................########################"
  },
  {
    "................................................................",
    "................................................................",
    "......g...................o.........................g...........",
    ".....#####..............#####.....................#####.........",
    "................................................................",
    "..............F..........................H.....................",
    "............#####......................#####....................",
    "..P..................o.................................o.....N.",
    "#########.........#####...........############......###########",
    "................................................................",
    ".........................C....................F.................",
    ".......................#####................#####...............",
    "..........o.....................................................",
    "........#####...............#####....................#####......",
    "................................................................",
    "####################..##################..#####################"
  },
  {
    "................................................................",
    "................................................................",
    ".................................................................",
    ".....................#####..................#####...............",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "................................................................",
    "..P.................................................B...........",
    ".............................................................N..",
    "################################################################"
  }
};

void setup() {
  fullScreen();
  frameRate(60);
  musicaDeFundo = new SoundFile(this, "tapao_na_raba_8bit.mp3");
  musicaDeFundo.loop();
  
  // Carrega as folhas de sprites do jogador
  spriteIdle = loadImage("Idle.png");
  spriteRun = loadImage("Run.png");
  spriteAttack = loadImage("Attack_1.png");
  spriteJump = loadImage("Jump.png");
  
  // MODIFICADO: Carrega as folhas de sprites do Lobo (Inimigo Vermelho)
  spriteWolfRun = loadImage("Wolf_Run.png");
  spriteWolfAttack = loadImage("Wolf_Run+Attack.png");
  
  // Ajustado o número de colunas reais das imagens do jogador (96x96 cada frame)
  framesIdle = recortarSprites(spriteIdle, 6);
  framesRun = recortarSprites(spriteRun, 6);
  framesAttack = recortarSprites(spriteAttack, 4);
  framesJump = recortarSprites(spriteJump, 8);
  
  // MODIFICADO: Recorta as animações do lobo baseadas no número exato de frames das folhas (128x128 cada)
  framesWolfRun = recortarSprites(spriteWolfRun, 9);      // Wolf_Run tem 9 frames
  framesWolfAttack = recortarSprites(spriteWolfAttack, 7);  // Wolf_Run+Attack tem 7 frames
}

// Função auxiliar para fatiar horizontalmente a folha de sprites
PImage[] recortarSprites(PImage img, int colunas) {
  PImage[] frames = new PImage[colunas];
  int larg = img.width / colunas;
  int alt = img.height;
  for (int i = 0; i < colunas; i++) {
    frames[i] = img.get(i * larg, 0, larg, alt);
  }
  return frames;
}

void draw() {
  if (screen == MENU) menu();
  if (screen == PLAY) game();
  if (screen == GAMEOVER) endScreen("VOCÊ CAIU NO ABISMO", "Pressione ENTER para renascer");
  if (screen == WIN) endScreen("VITÓRIA", "Pontuação final: " + score);
}

void startGame() {
  level = 0;
  score = 0;
  camX = 0;
  loadLevel();
  screen = PLAY;
}

void loadLevel() {
  blocks.clear();
  enemies.clear();
  items.clear();
  particles.clear();
  bosses.clear();
  energyBalls.clear();

  String[] map = maps[level];

  for (int y = 0; y < map.length; y++) {
    for (int x = 0; x < map[y].length(); x++) {
      char c = map[y].charAt(x);
      float px = x * tile;
      float py = y * tile;

      if (c == '#') blocks.add(new Block(px, py));
      if (c == 'P') player = new Player(px, py);
      if (c == 'o') items.add(new Item(px + 12, py + 12, 0));
      if (c == 'g') items.add(new Item(px + 10, py + 10, 1));
      if (c == 'N') items.add(new Item(px + 8, py + 8, 2));

      if (c == 'C') enemies.add(new Enemy(px, py + 12, 0));
      if (c == 'F') enemies.add(new Enemy(px, py, 1));
      if (c == 'H') enemies.add(new Enemy(px, py + 8, 2));
      if (c == 'B') bosses.add(new Boss(px, py - 48));
    }
  }
}

void game() {
  float targetCam = constrain(player.x - width * 0.35, 0, maps[level][0].length() * tile - width);
  camX = lerp(camX, targetCam, 0.08);

  drawBackground();

  pushMatrix();
  translate(-camX, 0);

  for (Block b : blocks) b.show();

  updateItems();
  updateEnemies();
  updateBosses();
  updateEnergyBalls();

  player.update();
  player.show();

  updateParticles();

  popMatrix();

  hud();

  if (player.hp <= 0) screen = GAMEOVER;

  jumpPressed = false;
}

void updateItems() {
  boolean goNext = false;

  for (Item i : items) {
    i.update();
    i.show();

    if (!i.collected && player.box().hit(i.box())) {
      if (i.type == 2 && bossAlive()) {
        burst(i.x, i.y, color(190, 90, 255));
        continue;
      }

      i.collected = true;

      if (i.type == 0) score += 100;
      if (i.type == 1) score += 300;
      if (i.type == 2) goNext = true;

      burst(i.x, i.y, color(190, 230, 255));
    }
  }

  if (goNext) nextLevel();
}

void updateEnemies() {
  for (Enemy e : enemies) {
    e.update();
    e.show();

    if (e.dead) continue;

    if (player.attacking && player.attackBox().hit(e.box())) {
      if (e.hurtCooldown <= 0) {
        player.gainEnergy(); 
      }
      e.hitByPlayer(1);
    }

    if (!player.invincible && player.box().hit(e.box())) {
      player.damage();
      burst(player.x, player.y, color(255, 80, 100));
    }
  }
}

void updateBosses() {
  for (Boss b : bosses) {
    b.update();
    b.show();

    if (b.dead) continue;

    if (player.attacking && player.attackBox().hit(b.box())) {
      if (b.hurtCooldown <= 0) {
        player.gainEnergy();
      }
      b.hitByPlayer(1);
    }

    if (!player.invincible && player.box().hit(b.box())) {
      player.damage();
      burst(player.x, player.y, color(255, 80, 110));
    }
  }
}

void updateEnergyBalls() {
  for (int i = energyBalls.size() - 1; i >= 0; i--) {
    EnergyBall eb = energyBalls.get(i);
    eb.update();
    eb.show();

    boolean hitWall = false;
    for (Block b : blocks) {
      if (eb.box().hit(b.box())) {
        hitWall = true;
        break;
      }
    }

    for (Enemy e : enemies) {
      if (!e.dead && eb.box().hit(e.box())) {
        e.hitByPlayer(3); 
        burst(eb.x, eb.y, color(0, 255, 200));
      }
    }

    boolean hitBoss = false;
    for (Boss b : bosses) {
      if (!b.dead && eb.box().hit(b.box())) {
        b.hitByPlayer(3);
        hitBoss = true;
        break;
      }
    }

    if (hitWall || hitBoss || eb.x < camX - 100 || eb.x > camX + width + 100) {
      burst(eb.x, eb.y, color(0, 220, 255));
      energyBalls.remove(i);
    }
  }
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.show();

    if (p.life <= 0) particles.remove(i);
  }
}

void nextLevel() {
  level++;
  if (level >= maps.length) {
    screen = WIN;
  } else {
    loadLevel();
  }
}

boolean bossAlive() {
  for (Boss b : bosses) {
    if (!b.dead) return true;
  }
  return false;
}

boolean solidAt(float x, float y) {
  for (Block b : blocks) {
    if (x >= b.x && x <= b.x + tile && y >= b.y && y <= b.y + tile) {
      return true;
    }
  }
  return false;
}

void drawBackground() {
  background(8, 10, 18);
  noStroke();
  fill(15, 18, 34);
  rect(0, 0, width, height);

  fill(120, 40, 80, 20);
  ellipse(width * 0.35, height * 0.45, 620, 360);

  fill(70, 120, 210, 24);
  ellipse(width * 0.65, height * 0.35, 520, 300);

  fill(22, 26, 46);
  for (int i = 0; i < 12; i++) {
    float x = i * 140 - (camX * 0.18 % 140);
    triangle(x, 0, x + 55, 170, x + 110, 0);
  }

  fill(9, 12, 22, 190);
  for (int i = 0; i < 10; i++) {
    float x = i * 180 - (camX * 0.08 % 180);
    ellipse(x, 520, 280, 150);
  }

  for (int i = 0; i < 25; i++) {
    float sx = (i * 211 - camX * 0.35) % width;
    float sy = 70 + sin(frameCount * 0.01 + i) * 18 + i * 13 % 330;
    fill(160, 210, 255, 35);
    ellipse(sx, sy, 3, 3);
  }
}

void hud() {
  fill(0, 165);
  rect(20, 18, 330, 85, 12);

  fill(240);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("Essência: " + score, 40, 78);
  text("Fase: " + (level + 1), 220, 78);

  for (int i = 0; i < player.hp; i++) {
    fill(245);
    ellipse(48 + i * 30, 34, 18, 18);
    fill(0);
    ellipse(48 + i * 30, 34, 6, 8);
  }

  fill(40, 50, 70);
  rect(40, 52, 120, 10, 4);
  
  if (player.energy >= 3) {
    fill(0, 255, 210, 180 + sin(frameCount * 0.2) * 75); 
  } else {
    fill(0, 190, 255);
  }
  float barWidth = map(player.energy, 0, 3, 0, 120);
  rect(40, 52, barWidth, 10, 4);
  
  textSize(11);
  fill(200);
  text(player.energy >= 3 ? "ESFERA PRONTA [K]" : "CARGA: " + player.energy + "/3", 170, 56);
}

void menu() {
  drawBackground();
  fill(0, 180);
  rect(0, 0, width, height);

  textAlign(CENTER, CENTER);
  fill(245);
  textSize(50);
  text("DANÇA DO ABISMO", width / 2, height / 2 - 110);

  fill(210);
  textSize(22);
  text("ENTER - iniciar", width / 2, height / 2 - 40);

  fill(0, 255, 210);
  textSize(18);
  text("NOVO PODER: Acerte 3 golpes para carregar a barra e aperte [K]", width / 2, height / 2 + 15);
  text("para disparar uma devastadora Esfera de Energia Arcana!", width / 2, height / 2 + 40);

  fill(180);
  textSize(16);
  text("A/D ou setas - mover | Espaço - pular | J - ataque básico", width / 2, height / 2 + 95);
}

void endScreen(String title, String sub) {
  fill(0, 195);
  rect(0, 0, width, height);
  textAlign(CENTER, CENTER);
  fill(245);
  textSize(48);
  text(title, width / 2, height / 2 - 45);
  fill(220);
  textSize(22);
  text(sub, width / 2, height / 2 + 20);
  if (screen != WIN) {
    text("ENTER - reiniciar", width / 2, height / 2 + 65);
  }
}

void burst(float x, float y, color c) {
  for (int i = 0; i < 14; i++) {
    particles.add(new Particle(x, y, c));
  }
}

void keyPressed() {
  if (screen == MENU && keyCode == ENTER) startGame();
  if (screen == GAMEOVER && keyCode == ENTER) startGame();

  if (key == 'a' || keyCode == LEFT) left = true;
  if (key == 'd' || keyCode == RIGHT) right = true;

  if (key == 'w' || keyCode == UP || key == ' ') {
    if (!jump) jumpPressed = true;
    jump = true;
  }

  if (key == 'j' || key == 'J') atk = true;
  if (key == 'k' || key == 'K') castBall = true;
}

void keyReleased() {
  if (key == 'a' || keyCode == LEFT) left = false;
  if (key == 'd' || keyCode == RIGHT) right = false;
  if (key == 'w' || keyCode == UP || key == ' ') jump = false;
  if (key == 'j' || key == 'J') atk = false;
  if (key == 'k' || key == 'K') castBall = false;
}

class Box {
  float x, y, w, h;
  Box(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
  }
  boolean hit(Box b) {
    return x < b.x + b.w && x + w > b.x && y < b.y + b.h && y + h > b.y;
  }
}

class Player {
  float x, y, w = 57, h = 96; 
  float vx, vy;
  float acc = 0.58;
  float maxSpeed = 5.8;
  float friction = 0.84;

  int hp = 5;
  int energy = 0; 
  int dir = 1;
  int attackTime = 0;
  int invTime = 0;
  int coyoteTime = 0;
  int jumpBuffer = 0;

  boolean grounded = false, attacking = false, invincible = false;

  Player(float x, float y) {
    this.x = x; 
    this.y = y - 48; 
  }

  void gainEnergy() {
    if (energy < 3) {
      energy++;
    }
  }

  void update() {
    float input = 0;
    if (left) input -= 1;
    if (right) input += 1;

    if (input != 0) {
      vx += input * acc;
      dir = input > 0 ? 1 : -1;
    } else {
      vx *= friction;
    }

    vx = constrain(vx, -maxSpeed, maxSpeed);
    if (abs(vx) < 0.05) vx = 0;

    if (grounded) coyoteTime = 8;
    else coyoteTime--;

    if (jumpPressed) jumpBuffer = 8;
    else jumpBuffer--;

    if (jumpBuffer > 0 && coyoteTime > 0) {
      vy = -14.2;
      grounded = false;
      jumpBuffer = 0;
      coyoteTime = 0;
      burst(x + w / 2, y + h, color(170, 220, 255));
    }

    if (!jump && vy < -4) vy *= 0.52;

    float gravity = jump && vy < 0 ? 0.36 : 0.78;
    vy = min(vy + gravity, 15);

    if (atk && attackTime <= 0) {
      attackTime = 22;
      burst(x + w / 2 + dir * 66, y + 37.5, color(230, 245, 255));
    }

    if (castBall && energy >= 3) {
      energy = 0; 
      energyBalls.add(new EnergyBall(x + w/2, y + h/2 - 15, dir));
      burst(x + w/2, y + h/2, color(0, 255, 230));
    }

    attacking = attackTime > 0;
    if (attackTime > 0) attackTime--;

    if (invincible) {
      invTime--;
      if (invTime <= 0) invincible = false;
    }

    move(vx, 0);
    move(0, vy);

    if (y > height + 200) hp = 0;
  }

  void move(float dx, float dy) {
    x += dx; y += dy;
    if (dy != 0) grounded = false;

    for (Block b : blocks) {
      if (box().hit(b.box())) {
        if (dx > 0) { x = b.x - w; vx = 0; }
        if (dx < 0) { x = b.x + tile; vx = 0; }
        if (dy > 0) { y = b.y - h; vy = 0; grounded = true; }
        if (dy < 0) { y = b.y + tile; vy = 0; }
      }
    }
  }

  void damage() {
    hp--;
    invincible = true;
    invTime = 70;
    vy = -8;
    vx = -dir * 6;
  }

  Box box() { return new Box(x + 9, y + 7.5, w - 18, h - 7.5); }
  
  Box attackBox() {
    if (!attacking) return new Box(-9999, -9999, 1, 1);
    return new Box(x + (dir == 1 ? w : -99), y + 12, 99, 66);
  }

  void show() {
    if (invincible && frameCount % 8 < 4) return;

    PImage frameAtual = null;

    if (attacking) {
      int idx = int(map(22 - attackTime, 0, 22, 0, framesAttack.length));
      idx = constrain(idx, 0, framesAttack.length - 1);
      frameAtual = framesAttack[idx];
    } 
    else if (!grounded) {
      int idx = int(map(vy, -14.2, 15, 0, framesJump.length));
      idx = constrain(idx, 0, framesJump.length - 1);
      frameAtual = framesJump[idx];
    } 
    else if (abs(vx) > 0.5) {
      int idx = (frameCount / 5) % framesRun.length;
      frameAtual = framesRun[idx];
    } 
    else {
      int idx = (frameCount / 6) % framesIdle.length;
      frameAtual = framesIdle[idx];
    }

    if (frameAtual != null) {
      pushMatrix();
      translate(x + w / 2, y + h);
      scale(dir, 1);

      float renderH = h * 1.1875; 
      float aspecto = (float)frameAtual.width / frameAtual.height;
      float renderW = renderH * aspecto;

      imageMode(CENTER);
      image(frameAtual, 0, -renderH / 2, renderW, renderH);
      popMatrix();
    }
  }
}

class EnergyBall {
  float x, y, r = 24;
  float speed = 9.5;
  int dir;
  float t = 0;

  EnergyBall(float x, float y, int dir) {
    this.x = x; this.y = y; this.dir = dir;
  }
  void update() { x += speed * dir; t += 0.2; }
  Box box() { return new Box(x - r/2, y - r/2, r, r); }
  void show() {
    noStroke(); fill(0, 255, 200, 70 + sin(t)*30); ellipse(x, y, r + 16, r + 16);
    fill(230, 255, 255); ellipse(x, y, r, r);
    if (frameCount % 2 == 0) { particles.add(new Particle(x - dir * 10, y + random(-5, 5), color(0, 210, 255))); }
  }
}

class Block {
  float x, y;
  Block(float x, float y) { this.x = x; this.y = y; }
  Box box() { return new Box(x, y, tile, tile); }
  void show() {
    noStroke(); fill(18, 22, 36); rect(x, y, tile, tile);
    fill(42, 50, 78); rect(x, y, tile, 12);
    fill(28, 34, 55); rect(x + 4, y + 16, tile - 8, tile - 20, 6);
    stroke(95, 145, 210, 45); line(x + 8, y + 18, x + 36, y + 42);
    stroke(0, 90); line(x, y + tile - 1, x + tile, y + tile - 1);
  }
}

class Enemy {
  float x, y, startY;
  float w = 44, h = 34, vx = 1.4, vy = 0;
  int type, hp, dir = 1, hurtCooldown = 0;
  boolean dead = false, grounded = false;

  Enemy(float x, float y, int type) {
    this.x = x; this.y = y; this.startY = y; this.type = type;
    if (type == 0) { hp = 2; w = 48; h = 32; }
    if (type == 1) { hp = 1; w = 44; h = 44; y -= 45; startY = y; }
    if (type == 2) { hp = 3; w = 50; h = 42; } // Inimigo Vermelho (Hunter)
  }

  void update() {
    if (dead) return;
    if (hurtCooldown > 0) hurtCooldown--;
    if (type == 0) crawler();
    if (type == 1) flyer();
    if (type == 2) hunter();
  }

  void crawler() {
    float dx = player.x - x;
    boolean sees = abs(dx) < 240 && abs(player.y - y) < 110;
    vx = sees ? lerp(vx, (dx > 0 ? 1 : -1) * 2.3, 0.06) : dir * 1.3;
    float front = (vx > 0) ? x + w + 6 : x - 6;
    if (!solidAt(front, y + h + 12) || solidAt(front, y + h / 2)) { dir *= -1; vx = dir * 1.3; }
    vy = min(vy + 0.65, 14);
    move(vx, 0); move(0, vy);
  }

  void flyer() {
    float dx = player.x - x;
    if (abs(dx) < 320 && abs(player.y - y) < 180) {
      vx = lerp(vx, (dx > 0 ? 1 : -1) * 2.5, 0.045);
      y += sin(frameCount * 0.12) * 0.9;
    } else {
      vx = dir * 1.15; y = startY + sin(frameCount * 0.08 + x * 0.01) * 24;
    }
    x += vx;
    if (solidAt(x + w / 2, y + h / 2)) { dir *= -1; vx *= -1; }
  }

  void hunter() {
    float dx = player.x - x;
    boolean sees = abs(dx) < 360 && abs(player.y - y) < 170;
    vx = sees ? lerp(vx, (dx > 0 ? 1 : -1) * 3.2, 0.08) : dir * 1.45;
    float front = (vx > 0) ? x + w + 8 : x - 8;
    if (!sees && (!solidAt(front, y + h + 14) || solidAt(front, y + h / 2))) dir *= -1;
    if (sees && grounded && (solidAt(front, y + h / 2) || !solidAt(front, y + h + 14))) {
      vy = -10.8; grounded = false;
      burst(x + w / 2, y + h, color(140, 180, 255));
    }
    vy = min(vy + 0.68, 14);
    move(vx, 0); move(0, vy);
  }

  void move(float dx, float dy) {
    x += dx; y += dy; if (dy != 0) grounded = false;
    for (Block b : blocks) {
      if (box().hit(b.box())) {
        if (dx > 0) { x = b.x - w; dir = -1; }
        if (dx < 0) { x = b.x + tile; dir = 1; }
        if (dy > 0) { y = b.y - h; vy = 0; grounded = true; }
        if (dy < 0) { y = b.y + tile; vy = 0; }
      }
    }
  }

  void hitByPlayer(int damageValue) {
    if (hurtCooldown > 0) return;
    hp -= damageValue;
    hurtCooldown = 18;
    vx = player.dir * 4.5; vy = -4;
    burst(x + w / 2, y + h / 2, color(230, 245, 255));

    if (hp <= 0) {
      dead = true; score += 250;
      burst(x + w / 2, y + h / 2, color(120, 180, 255));
    }
  }

  Box box() { return new Box(x + 4, y + 4, w - 8, h - 6); }
  
  void show() {
    if (dead) return;
    pushMatrix();
    translate(x + w / 2, y + h / 2);
    if (dir < 0) scale(-1, 1);
    if (type == 0) drawCrawler();
    if (type == 1) drawFlyer();
    if (type == 2) drawHunter(); // MODIFICADO: Passou a carregar as spritesheets do lobo
    popMatrix();
  }

  void drawCrawler() {
    float pulse = sin(frameCount * 0.15) * 2; noStroke();
    fill(hurtCooldown > 0 ? color(255, 220, 230) : color(42, 48, 75)); ellipse(0, pulse, w, h);
    fill(230); ellipse(-11, -7 + pulse, 12, 12); ellipse(11, -7 + pulse, 12, 12);
    fill(0); ellipse(-11, -7 + pulse, 5, 5); ellipse(11, -7 + pulse, 5, 5);
    stroke(120, 180, 240); strokeWeight(3); line(-15, 12, -28, 22); line(15, 12, 28, 22);
  }

  void drawFlyer() {
    float wing = sin(frameCount * 0.35) * 12; noStroke();
    fill(hurtCooldown > 0 ? color(255, 220, 240) : color(65, 48, 92)); ellipse(0, 0, w, h);
    fill(48, 38, 76); triangle(-16, -3, -43, -18 + wing, -20, 15); triangle(16, -3, 43, -18 + wing, 20, 15);
    fill(240); ellipse(-8, -5, 9, 12); ellipse(8, -5, 9, 12);
    fill(0); ellipse(-8, -5, 4, 5); ellipse(8, -5, 4, 5);
  }

  // MODIFICADO: Substituídos os blocos geométricos originais pelas animações fluidas do lobo
  void drawHunter() {
    float dx = player.x - x;
    // Verifica se o lobo detectou o jogador baseado no raio de visão original
    boolean sees = abs(dx) < 360 && abs(player.y - y) < 170;
    
    PImage frameAtual;
    if (sees) {
      // Se estiver perseguindo, usa a animação agressiva (7 frames) em velocidade rápida
      int idx = (frameCount / 4) % framesWolfAttack.length;
      frameAtual = framesWolfAttack[idx];
    } else {
      // Se estiver calmo patrulhando, usa a animação estável de corrida (9 frames)
      int idx = (frameCount / 5) % framesWolfRun.length;
      frameAtual = framesWolfRun[idx];
    }
    
    if (frameAtual != null) {
      // Escalona a imagem quadrada (128x128) para casar de forma proporcional com a colisão do jogo
      float renderH = h * 1.35; 
      float renderW = renderH; 
      
      if (hurtCooldown > 0) {
        tint(255, 100, 100); // Pisca em vermelho ao sofrer dano do jogador
      }
      
      imageMode(CENTER);
      // O offset de Y ajusta dinamicamente as patas na linha do chão de acordo com o tamanho do colisor
      image(frameAtual, 0, (h - renderH) / 2, renderW, renderH);
      
      if (hurtCooldown > 0) {
        noTint();
      }
    }
  }
}

class Boss {
  float x, y, w = 92, h = 96, vx = 0, vy = 0;
  int hp = 18, maxHp = 18, dir = -1, stateTimer = 70, hurtCooldown = 0;
  boolean grounded = false, dead = false;

  Boss(float x, float y) { this.x = x; this.y = y; }

  void update() {
    if (dead) return;
    if (hurtCooldown > 0) hurtCooldown--;
    dir = player.x > x ? 1 : -1;
    stateTimer--;

    if (stateTimer <= 0) {
      if (random(1) < 0.45 && grounded) {
        vy = -13; vx = dir * 4.5; stateTimer = 65;
        burst(x + w / 2, y + h, color(180, 100, 255));
      } else { stateTimer = 80; }
    }
    vx = lerp(vx, (abs(player.x - x) < 160 ? dir * 6.5 : dir * 2.4), 0.05);
    vy = min(vy + 0.7, 16);
    move(vx, 0); move(0, vy);
  }

  void move(float dx, float dy) {
    x += dx; y += dy; if (dy != 0) grounded = false;
    for (Block b : blocks) {
      if (box().hit(b.box())) {
        if (dx > 0) { x = b.x - w; vx *= -0.3; }
        if (dx < 0) { x = b.x + tile; vx *= -0.3; }
        if (dy > 0) { y = b.y - h; vy = 0; grounded = true; }
        if (dy < 0) { y = b.y + tile; vy = 0; }
      }
    }
  }

  void hitByPlayer(int damageValue) {
    if (hurtCooldown > 0) return;
    hp -= damageValue;
    hurtCooldown = 16;
    vx = player.dir * 4; vy = -3;
    burst(x + w / 2, y + h / 2, color(230, 245, 255));

    if (hp <= 0) {
      dead = true; score += 2000;
      burst(x + w / 2, y + h / 2, color(255, 210, 120));
    }
  }

  Box box() { return new Box(x + 10, y + 8, w - 20, h - 8); }
  
  void show() {
    if (dead) return;
    float pulse = sin(frameCount * 0.12) * 4;
    pushMatrix(); translate(x + w / 2, y + h / 2); scale(dir, 1);
    noStroke(); fill(hurtCooldown > 0 ? color(255, 220, 235) : color(80, 42, 92)); ellipse(0, 8 + pulse, w, h);
    fill(160, 28, 55); beginShape(); vertex(-40, -5); vertex(40, -5); vertex(32, 55); vertex(0, 75); vertex(-32, 55); endShape(CLOSE);
    fill(245); ellipse(0, -22 + pulse, 52, 48);
    fill(245); triangle(-22, -48, -44, -96, -8, -45); triangle(22, -48, 44, -96, 8, -45);
    fill(0); ellipse(-13, -23 + pulse, 8, 14); ellipse(13, -23 + pulse, 8, 14);
    stroke(245); strokeWeight(5); line(32, 4, 88, -6);
    stroke(255, 120, 170, 120); strokeWeight(3); line(42, -6, 96, -20); line(42, 8, 96, 18);
    popMatrix();
    showHealthBar();
  }

  void showHealthBar() {
    float bw = 520, bh = 18, bx = camX + width / 2 - bw / 2, by = 102;
    fill(0, 180); rect(bx, by, bw, bh, 8);
    fill(175, 42, 95); rect(bx, by, bw * hp / maxHp, bh, 8);
    fill(240); textAlign(CENTER, CENTER); textSize(16); text("DAMA DO ABISMO", camX + width / 2, by - 16);
  }
}

class Item {
  float x, y; int type; float t = random(TWO_PI); boolean collected = false;
  Item(float x, float y, int type) { this.x = x; this.y = y; this.type = type; }
  void update() { t += 0.08; }
  Box box() { return new Box(x, y, 28, 28); }
  void show() {
    if (collected) return;
    float yy = y + sin(t) * 5; float glow = 34 + sin(t * 2) * 8; noStroke();
    fill(type == 0 ? color(150, 210, 255, 70) : type == 1 ? color(255, 210, 80, 80) : color(190, 120, 255, 90)); ellipse(x + 14, yy + 14, glow, glow);
    if (type == 0) { fill(220, 245, 255); ellipse(x + 14, yy + 14, 22, 22); fill(120, 180, 240); ellipse(x + 14, yy + 14, 8, 8); }
    if (type == 1) { fill(255, 225, 90); beginShape(); vertex(x + 14, yy); vertex(x + 28, yy + 14); vertex(x + 14, yy + 28); vertex(x, yy + 14); endShape(CLOSE); fill(255, 250, 180); ellipse(x + 10, yy + 10, 6, 6); }
    if (type == 2) { fill(160, 100, 255); ellipse(x + 14, yy + 14, 30, 30); fill(255); textAlign(CENTER, CENTER); textSize(14); text("N", x + 14, yy + 13); }
  }
}

class Particle {
  float x, y, vx, vy, life = 255; color c;
  Particle(float x, float y, color c) { this.x = x; this.y = y; this.c = c; vx = random(-3, 3); vy = random(-4, 2); }
  void update() { x += vx; y += vy; vy += 0.12; life -= 8; }
  void show() { noStroke(); fill(c, life); ellipse(x, y, 5, 5); }
}
