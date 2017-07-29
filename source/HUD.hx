 package;

 import flixel.FlxBasic;
 import flixel.FlxG;
 import flixel.FlxSprite;
 import flixel.group.FlxGroup.FlxTypedGroup;
 import flixel.text.FlxText;
 import flixel.util.FlxColor;
 using flixel.util.FlxSpriteUtil;

 class HUD extends FlxTypedGroup<FlxSprite>
 {
    private var _batteryContainerSprite:FlxSprite;
    private var _batteryContentSprite:FlxSprite;
    private var _batteryEnergyText:FlxText;

    private var _batteryMaxEnergyValue:Int;

    private var _batteryContentInitialHeight:Int;

    private var _scoreText:FlxText;

    public function new()
    {
        super();

        _batteryContentInitialHeight = 100;
        _batteryMaxEnergyValue = 1000;

        _batteryContentSprite = new FlxSprite().makeGraphic(20, _batteryContentInitialHeight, FlxColor.YELLOW);
        _batteryContentSprite.x = FlxG.width - 50;
        _batteryContentSprite.y = 20;
        _batteryContentSprite.origin.set(_batteryContentSprite.width / 2, _batteryContentSprite.height);

        _batteryEnergyText = new FlxText(FlxG.width - 50, 5, 0, "", 8);
        _batteryEnergyText.setBorderStyle(SHADOW, FlxColor.GRAY, 1, 1);

        add(_batteryContentSprite);
        add(_batteryEnergyText);

        _scoreText = new FlxText(FlxG.width / 2, 50, 0, "Score 0", 16);
        _scoreText.setBorderStyle(SHADOW, FlxColor.GRAY, 1, 1);

        add(_scoreText);

        // The UI sprites will stays at their position on the screen
        // even if the camera moves
        forEach(function(spr:FlxSprite)
        {
            spr.scrollFactor.set(0, 0);
        });
    }
    public function setScore(score:Int):Void
    {
        _scoreText.text = "Score " + Std.string(score);
    }

    public function setEnergy(energy:Int = 0):Void
    {
        var percent = energy / _batteryMaxEnergyValue;
        _batteryEnergyText.text = Std.string(cast(Math.ceil(percent * 100), Int)) + "%";
        _batteryContentSprite.scale.y = percent;

        if (percent > 0.75)
            _batteryContentSprite.color = 0x1D773E;
        else if (percent > 0.3)
            _batteryContentSprite.color = 0xFF6A00;
        else
            _batteryContentSprite.color = 0xFF0000;
    }

    public function shakeBattery(Intensity:Float)
    {
    }
 }