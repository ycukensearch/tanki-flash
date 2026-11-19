// ===== КОД ДЛЯ КАДРА 1 =====
stage.scaleMode = "noScale";
stage.align = "TL";
Stage.showMenu = false;
fscommand("allowscale", "true");

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFormat;

Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

// ===== КОНСТАНТЫ =====
var W:Number = 480;
var H:Number = 800;
stage.stageWidth = W;
stage.stageHeight = H;

var playerSpeed:Number = 3;
var bulletSpeed:Number = 8;
var enemySpeed:Number = 1.2;
var enemyShootDelay:Number = 90;

// ===== ИГРОВЫЕ ПЕРЕМЕННЫЕ =====
var player:Sprite;
var bullets:Array = [];
var enemies:Array = [];
var enemyBullets:Array = [];
var walls:Array = [];
var score:int = 0;
var gameOver:Boolean = false;
var keys:Object = {};
var joystickActive:Boolean = false;
var joystickStart:Point = new Point(0,0);
var joystickCur:Point = new Point(0,0);
var joystickCenter:Point = new Point(80, H - 80);
var joystickRadius:Number = 50;
var fireButton:Point = new Point(W - 80, H - 80);
var fireButtonRadius:Number = 45;
var firePressed:Boolean = false;
var shootCooldown:int = 0;
var enemySpawnTimer:int = 0;

// ===== UI =====
var scoreText:TextField = new TextField();
scoreText.defaultTextFormat = new TextFormat("Arial", 22, 0xFFFFFF, true);
scoreText.text = "Счёт: 0";
scoreText.x = 10; scoreText.y = 10;
scoreText.width = 200;
addChild(scoreText);

var gameOverText:TextField = new TextField();
gameOverText.defaultTextFormat = new TextFormat("Arial", 40, 0xFF4444, true);
gameOverText.text = "";
gameOverText.width = W; gameOverText.height = 100;
gameOverText.x = 0; gameOverText.y = H/2 - 50;
gameOverText.selectable = false;
addChild(gameOverText);

// ===== СОЗДАНИЕ ТАНКА =====
function createTank(color:uint, size:Number):Sprite {
    var t:Sprite = new Sprite();
    // корпус
    t.graphics.beginFill(color);
    t.graphics.drawRect(-size, -size*0.7, size*2, size*1.4);
    t.graphics.endFill();
    // башня
    t.graphics.beginFill(color == 0x44AA44 ? 0x228822 : 0x882222);
    t.graphics.drawCircle(0, 0, size*0.55);
    t.graphics.endFill();
    // ствол
    t.graphics.beginFill(0x333333);
    t.graphics.drawRect(0, -size*0.15, size*1.6, size*0.3);
    t.graphics.endFill();
    return t;
}

// ===== ИНИЦИАЛИЗАЦИЯ =====
function init():void {
    // очистка
    while (numChildren > 0) removeChildAt(0);
    bullets = []; enemies = []; enemyBullets = []; walls = [];
    score = 0; gameOver = false; keys = {};
    shootCooldown = 0; enemySpawnTimer = 0;
    
    // фон
    var bg:Sprite = new Sprite();
    bg.graphics.beginFill(0x3a3a2a);
    bg.graphics.drawRect(0, 0, W, H);
    bg.graphics.endFill();
    // сетка
    bg.graphics.lineStyle(1, 0x4a4a3a);
    for (var gx:int = 0; gx < W; gx += 40) {
        bg.graphics.moveTo(gx, 0); bg.graphics.lineTo(gx, H);
    }
    for (var gy:int = 0; gy < H; gy += 40) {
        bg.graphics.moveTo(0, gy); bg.graphics.lineTo(W, gy);
    }
    addChild(bg);
    
    // стены (препятствия)
    var wallData:Array = [
        [100, 200, 80, 30], [300, 200, 80, 30],
        [200, 400, 30, 80], [50, 600, 100, 30],
        [330, 600, 100, 30], [200, 650, 80, 80],
        [0, 350, 30, 150], [450, 350, 30, 150]
    ];
    for (var i:int = 0; i < wallData.length; i++) {
        var wd:Array = wallData[i];
        var wall:Sprite = new Sprite();
        wall.graphics.beginFill(0x666655);
        wall.graphics.drawRect(0, 0, wd[2], wd[3]);
        wall.graphics.endFill();
        wall.graphics.lineStyle(2, 0x888877);
        wall.graphics.drawRect(0, 0, wd[2], wd[3]);
        wall.x = wd[0]; wall.y = wd[1];
        wall.width = wd[2]; wall.height = wd[3];
        addChild(wall);
        walls.push(wall);
    }
    
    // игрок
    player = createTank(0x44AA44, 20);
    player.x = W/2; player.y = H - 150;
    addChild(player);
    
    // UI поверх
    addChild(scoreText);
    scoreText.text = "Счёт: 0";
    addChild(gameOverText);
    gameOverText.text = "";
    
    // слушатели
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
    stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
    stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
    stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
}

// ===== ВВОД =====
function onKeyDown(e:KeyboardEvent):void { keys[e.keyCode] = true; }
function onKeyUp(e:KeyboardEvent):void { keys[e.keyCode] = false; }

function onMouseDown(e:MouseEvent):void {
    if (e.stageX < W/2) {
        joystickActive = true;
        joystickStart = new Point(e.stageX, e.stageY);
        joystickCur = joystickStart.clone();
    } else {
        firePressed = true;
    }
}
function onMouseUp(e:MouseEvent):void {
    joystickActive = false;
    firePressed = false;
}
function onMouseMove(e:MouseEvent):void {
    if (joystickActive) joystickCur = new Point(e.stageX, e.stageY);
}

function onTouchBegin(e:TouchEvent):void {
    if (e.stageX < W/2) {
        joystickActive = true;
        joystickStart = new Point(e.stageX, e.stageY);
        joystickCur = joystickStart.clone();
    } else {
        firePressed = true;
    }
}
function onTouchMove(e:TouchEvent):void {
    if (joystickActive) joystickCur = new Point(e.stageX, e.stageY);
}
function onTouchEnd(e:TouchEvent):void {
    joystickActive = false;
    firePressed = false;
}

// ===== ЛОГИКА =====
function onEnterFrame(e:Event):void {
    if (gameOver) return;
    
    // движение игрока
    var dx:Number = 0, dy:Number = 0;
    if (keys[37] || keys[65]) dx -= 1; // left
    if (keys[39] || keys[68]) dx += 1; // right
    if (keys[38] || keys[87]) dy -= 1; // up
    if (keys[40] || keys[83]) dy += 1; // down
    
    // джойстик
    if (joystickActive) {
        var jdx:Number = joystickCur.x - joystickStart.x;
        var jdy:Number = joystickCur.y - joystickStart.y;
        var jlen:Number = Math.sqrt(jdx*jdx + jdy*jdy);
        if (jlen > 5) {
            dx = jdx / jlen;
            dy = jdy / jlen;
        }
    }
    
    // нормализация
    var len:Number = Math.sqrt(dx*dx + dy*dy);
    if (len > 0) { dx /= len; dy /= len; }
    
    var newX:Number = player.x + dx * playerSpeed;
    var newY:Number = player.y + dy * playerSpeed;
    
    // коллизии со стенами
    if (!hitsWall(newX, player.y, 18)) player.x = newX;
    if (!hitsWall(player.x, newY, 18)) player.y = newY;
    
    // границы
    player.x = Math.max(20, Math.min(W-20, player.x));
    player.y = Math.max(20, Math.min(H-20, player.y));
    
    // поворот башни к цели (мышь/тач) - упрощённо: к направлению движения
    if (len > 0) player.rotation = Math.atan2(dy, dx) * 180 / Math.PI;
    
    // стрельба
    if (shootCooldown > 0) shootCooldown--;
    if ((keys[32] || firePressed) && shootCooldown <= 0) {
        fireBullet();
        shootCooldown = 15;
    }
    
    // пули игрока
    for (var i:int = bullets.length - 1; i >= 0; i--) {
        var b:Sprite = bullets[i];
        b.x += b.vx; b.y += b.vy;
        if (b.x < 0 || b.x > W || b.y < 0 || b.y > H || hitsWall(b.x, b.y, 4)) {
            removeChild(b); bullets.splice(i, 1); continue;
        }
        // попадание по врагам
        var hit:Boolean = false;
        for (var j:int = enemies.length - 1; j >= 0; j--) {
            var en:Sprite = enemies[j];
            if (Math.abs(b.x - en.x) < 22 && Math.abs(b.y - en.y) < 22) {
                removeChild(en); enemies.splice(j, 1);
                removeChild(b); bullets.splice(i, 1);
                score += 10; scoreText.text = "Счёт: " + score;
                hit = true; break;
            }
        }
    }
    
    // спавн врагов
    enemySpawnTimer++;
    if (enemySpawnTimer > 120 && enemies.length < 6) {
        enemySpawnTimer = 0;
        spawnEnemy();
    }
    
    // враги
    for (var k:int = enemies.length - 1; k >= 0; k--) {
        var en2:Sprite = enemies[k];
        // движение к игроку
        var edx:Number = player.x - en2.x;
        var edy:Number = player.y - en2.y;
        var elen:Number = Math.sqrt(edx*edx + edy*edy);
        if (elen > 0) { edx /= elen; edy /= elen; }
        var enx:Number = en2.x + edx * enemySpeed;
        var eny:Number = en2.y + edy * enemySpeed;
        if (!hitsWall(enx, en2.y, 18)) en2.x = enx;
        if (!hitsWall(en2.x, eny, 18)) en2.y = eny;
        en2.rotation = Math.atan2(edy, edx) * 180 / Math.PI;
        
        // стрельба врагов
        en2.shootTimer = (en2.shootTimer || 0) + 1;
        if (en2.shootTimer > enemyShootDelay && elen < 400) {
            en2.shootTimer = 0;
            var eb:Sprite = new Sprite();
            eb.graphics.beginFill(0xFF4444);
            eb.graphics.drawCircle(0, 0, 5);
            eb.graphics.endFill();
            eb.x = en2.x; eb.y = en2.y;
            eb.vx = edx * 5; eb.vy = edy * 5;
            addChild(eb);
            enemyBullets.push(eb);
        }
        
        // столкновение с игроком
        if (Math.abs(en2.x - player.x) < 30 && Math.abs(en2.y - player.y) < 30) {
            endGame(); return;
        }
    }
    
    // пули врагов
    for (var m:int = enemyBullets.length - 1; m >= 0; m--) {
        var eb2:Sprite = enemyBullets[m];
        eb2.x += eb2.vx; eb2.y += eb2.vy;
        if (eb2.x < 0 || eb2.x > W || eb2.y < 0 || eb2.y > H || hitsWall(eb2.x, eb2.y, 4)) {
            removeChild(eb2); enemyBullets.splice(m, 1); continue;
        }
        if (Math.abs(eb2.x - player.x) < 22 && Math.abs(eb2.y - player.y) < 22) {
            endGame(); return;
        }
    }
    
    // отрисовка джойстика
    drawJoystick();
}

var joystickGfx:Sprite;
function drawJoystick():void {
    if (!joystickGfx) { joystickGfx = new Sprite(); addChild(joystickGfx); }
    joystickGfx.graphics.clear();
    if (joystickActive) {
        joystickGfx.graphics.lineStyle(2, 0xFFFFFF, 0.5);
        joystickGfx.graphics.drawCircle(joystickStart.x, joystickStart.y, joystickRadius);
        var jdx:Number = joystickCur.x - joystickStart.x;
        var jdy:Number = joystickCur.y - joystickStart.y;
        var jlen:Number = Math.sqrt(jdx*jdx + jdy*jdy);
        if (jlen > joystickRadius) { jdx = jdx/jlen*joystickRadius; jdy = jdy/jlen*joystickRadius; }
        joystickGfx.graphics.beginFill(0xFFFFFF, 0.4);
        joystickGfx.graphics.drawCircle(joystickStart.x + jdx, joystickStart.y + jdy, 20);
        joystickGfx.graphics.endFill();
    }
}

function fireBullet():void {
    var b:Sprite = new Sprite();
    b.graphics.beginFill(0xFFFF44);
    b.graphics.drawCircle(0, 0, 4);
    b.graphics.endFill();
    b.x = player.x; b.y = player.y;
    var ang:Number = player.rotation * Math.PI / 180;
    b.vx = Math.cos(ang) * bulletSpeed;
    b.vy = Math.sin(ang) * bulletSpeed;
    addChild(b);
    bullets.push(b);
}

function spawnEnemy():void {
    var en:Sprite = createTank(0xAA4444, 20);
    // позиция на краю
    var side:int = Math.floor(Math.random() * 4);
    if (side == 0) { en.x = Math.random() * W; en.y = 20; }
    else if (side == 1) { en.x = Math.random() * W; en.y = H - 20; }
    else if (side == 2) { en.x = 20; en.y = Math.random() * H; }
    else { en.x = W - 20; en.y = Math.random() * H; }
    en.shootTimer = 0;
    addChild(en);
    enemies.push(en);
}

function hitsWall(x:Number, y:Number, r:Number):Boolean {
    for (var i:int = 0; i < walls.length; i++) {
        var w:Sprite = walls[i];
        if (x + r > w.x && x - r < w.x + w.width &&
            y + r > w.y && y - r < w.y + w.height) return true;
    }
    return false;
}

function endGame():void {
    gameOver = true;
    gameOverText.text = "ИГРА ОКОНЧЕНА\nСчёт: " + score + "\nНажмите для рестарта";
    gameOverText.height = 200;
    stage.addEventListener(MouseEvent.CLICK, restart);
    stage.addEventListener(TouchEvent.TOUCH_TAP, restart);
}

function restart(e:Event):void {
    stage.removeEventListener(MouseEvent.CLICK, restart);
    stage.removeEventListener(TouchEvent.TOUCH_TAP, restart);
    init();
}

// ===== СТАРТ =====
init();
