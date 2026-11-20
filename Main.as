package {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import flash.text.TextField;
    import flash.text.TextFormat;

    [SWF(width="800", height="600", backgroundColor="#2E3B23", frameRate="60")]
    public class Main extends Sprite {
        private var player:Sprite;
        private var enemy:Sprite;
        private var bullets:Array = [];
        private var enemyBullets:Array = [];
        private var keys:Object = {};
        private var score:int = 0;
        private var scoreText:TextField;
        private var enemyMoveTimer:int = 0;

        public function Main() {
            setupUI();
            player = createTank(0x4CAF50); // Зеленый танк игрока
            player.x = 100;
            player.y = 300;
            addChild(player);

            enemy = createTank(0xF44336); // Красный танк врага
            respawnEnemy();
            addChild(enemy);

            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            addEventListener(Event.ENTER_FRAME, gameLoop);
        }

        private function setupUI():void {
            var format:TextFormat = new TextFormat("Arial", 20, 0xFFFFFF, true);
            scoreText = new TextField();
            scoreText.defaultTextFormat = format;
            scoreText.text = "Счет: 0";
            scoreText.x = 20;
            scoreText.y = 20;
            scoreText.width = 200;
            addChild(scoreText);
        }

        private function createTank(color:uint):Sprite {
            var tank:Sprite = new Sprite();
            // Корпус
            tank.graphics.beginFill(color);
            tank.graphics.drawRect(-20, -15, 40, 30);
            tank.graphics.endFill();
            // Гусеницы
            tank.graphics.beginFill(0x111111);
            tank.graphics.drawRect(-22, -18, 44, 5);
            tank.graphics.drawRect(-22, 13, 44, 5);
            tank.graphics.endFill();
            // Дуло
            tank.graphics.beginFill(0xCCCCCC);
            tank.graphics.drawRect(0, -3, 28, 6);
            tank.graphics.endFill();
            // Башня
            tank.graphics.beginFill(0x333333);
            tank.graphics.drawCircle(0, 0, 10);
            tank.graphics.endFill();
            return tank;
        }

        private function onKeyDown(e:KeyboardEvent):void {
            if (e.keyCode == Keyboard.SPACE && !keys[Keyboard.SPACE]) {
                shoot(player, bullets);
            }
            keys[e.keyCode] = true;
        }

        private function onKeyUp(e:KeyboardEvent):void {
            keys[e.keyCode] = false;
        }

        private function shoot(shooter:Sprite, bulletArray:Array):void {
            var bullet:Sprite = new Sprite();
            bullet.graphics.beginFill(0xFFEB3B);
            bullet.graphics.drawCircle(0, 0, 4);
            bullet.graphics.endFill();

            var angleRad:Number = shooter.rotation * Math.PI / 180;
            bullet.x = shooter.x + Math.cos(angleRad) * 30;
            bullet.y = shooter.y + Math.sin(angleRad) * 30;
            bullet.rotation = shooter.rotation;

            addChild(bullet);
            bulletArray.push(bullet);
        }

        private function gameLoop(e:Event):void {
            movePlayer();
            updateEnemy();
            updateBullets(bullets, enemy, true);
            updateBullets(enemyBullets, player, false);
        }

        private function movePlayer():void {
            var speed:Number = 3;
            var rotSpeed:Number = 3;
            if (keys[Keyboard.LEFT]) player.rotation -= rotSpeed;
            if (keys[Keyboard.RIGHT]) player.rotation += rotSpeed;

            var angleRad:Number = player.rotation * Math.PI / 180;
            if (keys[Keyboard.UP]) {
                player.x += Math.cos(angleRad) * speed;
                player.y += Math.sin(angleRad) * speed;
            }
            if (keys[Keyboard.DOWN]) {
                player.x -= Math.cos(angleRad) * speed;
                player.y -= Math.sin(angleRad) * speed;
            }
            keepInBounds(player);
        }

        private function updateEnemy():void {
            // Поворот в сторону игрока
            var dx:Number = player.x - enemy.x;
            var dy:Number = player.y - enemy.y;
            enemy.rotation = Math.atan2(dy, dx) * 180 / Math.PI;

            // Движение вперед
            var angleRad:Number = enemy.rotation * Math.PI / 180;
            enemy.x += Math.cos(angleRad) * 1.5;
            enemy.y += Math.sin(angleRad) * 1.5;
            keepInBounds(enemy);

            // Стрельба по таймеру
            enemyMoveTimer++;
            if (enemyMoveTimer > 90) {
                shoot(enemy, enemyBullets);
                enemyMoveTimer = 0;
            }
        }

        private function updateBullets(bulletArray:Array, target:Sprite, isPlayerBullet:Boolean):void {
            for (var i:int = bulletArray.length - 1; i >= 0; i--) {
                var b:Sprite = bulletArray[i];
                var angleRad:Number = b.rotation * Math.PI / 180;
                b.x += Math.cos(angleRad) * 8;
                b.y += Math.sin(angleRad) * 8;

                // Проверка попадания
                if (b.hitTestObject(target)) {
                    removeChild(b);
                    bulletArray.splice(i, 1);
                    if (isPlayerBullet) {
                        score += 100;
                        scoreText.text = "Счет: " + score;
                        respawnEnemy();
                    } else {
                        score = 0;
                        scoreText.text = "Вас подбили! Счет: 0";
                        player.x = 100;
                        player.y = 300;
                    }
                    continue;
                }

                // Удаление за пределами экрана
                if (b.x < 0 || b.x > 800 || b.y < 0 || b.y > 600) {
                    removeChild(b);
                    bulletArray.splice(i, 1);
                }
            }
        }

        private function respawnEnemy():void {
            enemy.x = 400 + Math.random() * 350;
            enemy.y = 50 + Math.random() * 500;
        }

        private function keepInBounds(obj:Sprite):void {
            if (obj.x < 25) obj.x = 25;
            if (obj.x > 775) obj.x = 775;
            if (obj.y < 25) obj.y = 25;
            if (obj.y > 575) obj.y = 575;
        }
    }
}
