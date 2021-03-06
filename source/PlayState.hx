package;

import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.FlxBasic;

class PlayState extends FlxState
{
	private var _map:TiledMap;
	private var _mWalls:FlxTilemap;
	private var _mBackground:FlxTilemap;
	private var _player:Player;
	private var _grpEnemySpawners:FlxTypedGroup<EnemySpawner>;

	private var _enemies:FlxTypedGroup<Enemy>;
	private var _batteries:FlxTypedGroup<Battery>;

	private var _teleporters:FlxTypedGroup<Teleporter>;
	private var _topTeleporters:Array<Teleporter>;
	private var _bottomTeleporters:Array<Teleporter>;

	private var _playerReviveTimer:FlxTimer;

	private var _score:Int = 0;

	private var _gameOver:Bool = false;

	private var _batterySpawner:BatterySpawner;

	// HUD
	private var _hud:HUD;

	private var _bullets:FlxTypedGroup<Bullet>;
	private var _megaBullets:FlxTypedGroup<MegaBullet>;

	override public function create():Void
	{
		FlxG.mouse.visible = false;
		_map = new TiledMap(AssetPaths.level0__tmx);
		_mWalls = new FlxTilemap();
		_mBackground = new FlxTilemap();
		_mWalls.loadMapFromArray(cast(_map.getLayer("Walls"), TiledTileLayer).tileArray, _map.width,
			_map.height, AssetPaths.tiles__png, _map.tileWidth, _map.tileHeight,
			FlxTilemapAutoTiling.OFF, 1, 1, 3);
		_mBackground.loadMapFromArray(cast(_map.getLayer("Background"), TiledTileLayer).tileArray, _map.width,
			_map.height, AssetPaths.tiles__png, _map.tileWidth, _map.tileHeight,
			FlxTilemapAutoTiling.OFF, 1, 1, 3);
		_mWalls.setTileProperties(2, FlxObject.NONE);
		_mWalls.setTileProperties(3, FlxObject.ANY);
		_mBackground.setTileProperties(2, FlxObject.NONE);
		_mBackground.setTileProperties(3, FlxObject.ANY);

		add(_mBackground);
		add(_mWalls);


		_enemies = new FlxTypedGroup<Enemy>();
		add(_enemies);

		_batteries = new FlxTypedGroup<Battery>();

		_topTeleporters = [];
		_bottomTeleporters = [];
		_teleporters = new FlxTypedGroup<Teleporter>();
		add(_teleporters);

		_grpEnemySpawners = new FlxTypedGroup<EnemySpawner>();
		add(_grpEnemySpawners);

		_player = new Player(this);
		_playerReviveTimer = new FlxTimer();

		_bullets = new FlxTypedGroup<Bullet>();
		add(_bullets);


		_megaBullets = new FlxTypedGroup<MegaBullet>();
		add(_megaBullets);

		// Parse map
		var tmpMapSpawn:TiledObjectLayer = cast _map.getLayer("Player");
		var tmpMapEnemySpawners:TiledObjectLayer = cast _map.getLayer("MobSpawners");

		for (e in tmpMapSpawn.objects) { placeSpawn(e);	}
		for (e in tmpMapEnemySpawners.objects) { placeEnemySpawners(e); }

		placeBatterySpawners(cast _map.getLayer("BatterySpawners"));
		placeTeleporters(cast _map.getLayer("TP"));

		add(_player);

		FlxG.camera.focusOn(new FlxPoint(_map.width * _map.tileWidth / 2.0, _map.height * _map.tileHeight / 2.0));
		FlxG.worldBounds.height = FlxG.worldBounds.height + 64;

	 	_hud = new HUD();
 		add(_hud);

		_hud.setScore(0);

		// Play music
		FlxG.sound.playMusic(AssetPaths.music__ogg, 1, true);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		FlxG.collide(_player, _mWalls);
		FlxG.collide(_enemies, _mWalls, onEnemyCollideWall);
		FlxG.overlap(_player, _enemies, onPlayerTouchEnemy);
		FlxG.overlap(_enemies, _bullets, onEnemyTouchBullet);
		FlxG.overlap(_enemies, _megaBullets, onEnemyTouchMegaBullet);
		FlxG.collide(_bullets, _mWalls, onBulletTouchWall);
		FlxG.collide(_megaBullets, _mWalls, onMegaBulletTouchWall);
		FlxG.overlap(_player, _teleporters, onObjectTouchTeleporter);
		FlxG.overlap(_enemies, _teleporters, onObjectTouchTeleporter);

 		_hud.setEnergy(cast _player.getEnergy());

		if (_gameOver && FlxG.keys.justPressed.X)
		{
			_gameOver = false;
			_hud.gameOver(false, "");
			playerRespawn();
		}
	}

	private function onObjectTouchTeleporter(entity:FlxObject, teleporter:Teleporter):Void
	{
		var destTp:Teleporter = teleporter.type == "top" ? FlxG.random.getObject(_bottomTeleporters) : FlxG.random.getObject(_topTeleporters);
		var offset:Int = teleporter.type == "top" ? -62 : 32;
		entity.y = destTp.y + offset;
		entity.x = destTp.x;
	}

	private function placeSpawn(e: TiledObject):Void
	{
		_player.setInitialPosition(e.x, e.y);
	}

	private function placeEnemySpawners(e:TiledObject):Void
	{
		_grpEnemySpawners.add(new EnemySpawner(this, e.x, e.y));
	}

	private function placeBatterySpawners(layer:TiledObjectLayer):Void
	{
		_batterySpawner = new BatterySpawner(this, _player);

		for (obj in layer.objects)
			_batterySpawner.addTile(obj);

		add(_batterySpawner);
	}

	private function placeTeleporters(layer:TiledObjectLayer):Void
	{
		for (e in layer.objects)
		{
			if (e.name == "top")
			{
				_topTeleporters.push(new Teleporter("top", e.x, e.y, e.width, e.height));
				_teleporters.add(new Teleporter("top", e.x, e.y, e.width, e.height));
			}
			if (e.name == "bottom")
			{
				_bottomTeleporters.push(new Teleporter("bottom", e.x, e.y, e.width, e.height));
				_teleporters.add(new Teleporter("bottom", e.x, e.y, e.width, e.height));
			}
		}
	}

	private function onPlayerTouchEnemy(player:Player, enemy:Enemy):Void
	{
		if (!player.alive || !player.exists || !enemy.alive || !enemy.exists) { return; }

		FlxObject.updateTouchingFlags(player, enemy);

		if ((player.justTouched(FlxObject.WALL) && enemy.justTouched(FlxObject.WALL)) ||
			(player.justTouched(FlxObject.UP) && enemy.justTouched(FlxObject.FLOOR)))
		{
			killPlayer("Killed by an enemy !");
		}
		else if (player.justTouched(FlxObject.DOWN) && enemy.justTouched(FlxObject.UP))
		{
			player.velocity.y = -100;
			killEnemy(enemy);
		}
	}

	private function onBulletTouchWall(bullet:Bullet, wall:FlxObject):Void
	{
		bullet.kill();
		_bullets.remove(bullet);
	}

	private function onMegaBulletTouchWall(megaBullet:MegaBullet, wall:FlxObject):Void
	{
		megaBullet.kill();
		_megaBullets.remove(megaBullet);
	}

	private function onEnemyTouchBullet(enemy:Enemy, bullet:Bullet):Void
	{
		killEnemy(enemy);
		bullet.kill();
		_bullets.remove(bullet);
	}

	private function onEnemyTouchMegaBullet(enemy:Enemy, megaBullet:MegaBullet):Void
	{
		killEnemy(enemy);
	}

	private function killEnemy(enemy:Enemy)
	{
		if (!enemy.alive)
			return;

		enemy.kill();

		addScore(5000);

		// 25% to drop battery
		if (FlxG.random.int(0, 3) == 0)
		{
			var battery = new Battery(this, _player, enemy.getGraphicMidpoint().x, enemy.getPosition().y + enemy.height - 4);
			battery.killed(function(battery:Battery)
			{
				remove(battery);
			});

			add(battery);
			addBattery(battery);
		}
	}

	public function addBattery(battery:Battery)
	{
		_batteries.add(battery);
	}

	private function playerRespawn():Void
	{
		_player.respawn();

		setScore(0);
	}

	private function onEnemyCollideWall(enemy:Enemy, wall:FlxObject):Void
	{
		if (enemy.justTouched(FlxObject.WALL))
			enemy.switchDirection();
	}

	public function addEnemy(x:Float, y:Float):Void
	{
		_enemies.add(new Enemy(x, y));
	}

	public function addBullet(x:Float, y:Float, direction:Int):Void
	{
		_bullets.add(new Bullet(x, y, direction));
	}

	public function addMegaBullet(x:Float, y:Float, direction:Int, scale:Float):Void
	{
		_megaBullets.add(new MegaBullet(x, y, direction, scale));
	}

	public function addEnergy(v:Int)
	{
		_player.addEnergy(v);
	}

	private function setScore(v:Int)
	{
		_score = v;

		_hud.setScore(_score);
	}

	public function addScore(v:Int)
	{
		setScore(_score + v);
	}

	public function killPlayer(reason:String = "Running out of Power !")
	{
		_player.kill();
		FlxG.camera.shake(.02, 0.5);

		_gameOver = true;
		_hud.gameOver(true, reason);

		_enemies.clear();

		for (battery in _batteries)
			remove(battery);
			
		_batteries.clear();
		
		_batterySpawner.despawnBattery();

		FlxG.sound.play(AssetPaths.death__ogg);
	}

	public function decreaseEnergy(v: Float)
	{
		_player.decreaseEnergy(v);


		if (v >= 3)
		{
			// HUD
			_hud.shakeBattery(1, 1);
		}
	}
}