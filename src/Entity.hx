import mt.MLib;
import mt.deepnight.Lib;
import mt.heaps.slib.*;

class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var destroyed(default,null) = false;
	public var cd : mt.Cooldown;
	public var tmod : Float;

	public var uid : Int;
    public var cx = 0;
    public var cy = 0;
    public var xr = 0.5;
    public var yr = 1.0;

    public var dx = 0.;
    public var dy = 0.;
	public var frict = 0.82;
	public var gravity = 0.024;
	public var hasGravity = true;
	public var weight = 1.;
	public var hei = Const.GRID;
	public var radius = Const.GRID*0.5;
	public var lifter = false;

	public var dir(default,set) = 1;
	public var hasColl = true;
	public var isAffectBySlowMo = true;
	public var lastHitDir = 0;
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;

    public var spr : HSprite;

	public var onGround(get,never) : Bool; inline function get_onGround() return ( level.hasColl(cx,cy+1) ) && yr>=1 && dy==0 || cd.has("lifted");
	// public var lifter : Null<Entity>;

	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var headX(get,never) : Float; inline function get_headX() return (cx+xr)*Const.GRID;
	public var headY(get,never) : Float; inline function get_headY() return (cy+yr)*Const.GRID-hei;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-radius;

    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
        ALL.push(this);

		cd = new mt.Cooldown(Const.FPS);

        setPosCase(x,y);

        spr = new HSprite(Assets.gameElements);
        Game.ME.scroller.add(spr, Const.DP_MAIN);
		spr.setCenterRatio(0.5,1);
        // var g = new h2d.Graphics(spr);
        // g.beginFill(0xff0000);
        // g.drawRect(0,0,radius,hei);
        // g.setPosition(-radius*0.5, -hei);
    }

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	public function setPosCase(x:Int, y:Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
	}

	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
	}

    public inline function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
        ALL.remove(this);
    }

    function onLand() {
        dy = 0;
    }
    function onTouchCeiling() {
    }

    function onTouchWall(wdir:Int) {
    }

    public function preUpdate(tmod:Float) {
        this.tmod = tmod;
		cd.update(tmod);
    }
    public function postUpdate() {
        spr.x = (cx+xr)*Const.GRID;
        spr.y = (cy+yr)*Const.GRID;
        spr.scaleX = dir*sprScaleX;
        spr.scaleY = sprScaleY;
    }


	function xSpecialPhysics() {
	}

	function ySpecialPhysics() {
	}

	public function canLift(e:Entity) {
		return e!=this && lifter;
	}

	function checkLifters() {
		if( level.hasColl(cx,cy-1) )
			return;

        for( e in ALL ) {
            if( !e.canLift(this) )
                continue;

            // Landing on another lifter
            if( dy>=0 && isStandingOn(e) ) {
                cy = e.cy-1;
                yr = e.yr;
                dy = 0;
                cd.setF("lifted",2);
				e.cd.setF("lifting", 2);
            }
        }
	}

	function isStandingOn(e:Entity) {
		return MLib.fabs(centerX-e.centerX)<=Const.GRID*0.6 && footY>=e.headY-1 && footY<=e.headY+8;
	}

	public inline function isLiftingSomeone() {
		return cd.has("lifting");
	}

	public inline function isLifted() {
		return cd.has("lifted");
	}

    public function update() {
		// X
		xSpecialPhysics();
		var steps = MLib.ceil( MLib.fabs(dx*tmod) );
		var step = dx*tmod / steps;
		while( steps>0 ) {
			xr+=step;
			if( hasColl ) {
				if( dx>=0 && xr>0.7 && level.hasColl(cx+1,cy) ) {
					xr = 0.7;
					onTouchWall(1);
					steps = 0;
				}
				if( dx<=0 && xr<0.3 && level.hasColl(cx-1,cy) ) {
					xr = 0.3;
					onTouchWall(-1);
					steps = 0;
				}
			}
			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frict,tmod);
		if( MLib.fabs(dx)<=0.01*tmod )
			dx = 0;

		// Gravity
		if( !onGround && hasGravity )
			dy += gravity*tmod;

		if( onGround )
			cd.setS("onGroundRecently",0.06);

		// Y
		ySpecialPhysics();
		var steps = MLib.ceil( MLib.fabs(dy*tmod) );
		var step = dy*tmod / steps;
		while( steps>0 ) {
			yr+=step;
			if( hasColl ) {
				if( yr>1 && level.hasColl(cx,cy+1) ) {
					yr = 1;
					onLand();
					steps = 0;
				}
				if( yr<0.2 && level.hasColl(cx,cy-1) ) {
					yr = 0.2;
					onTouchCeiling();
					steps = 0;
				}
			}
			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frict,tmod);
		if( MLib.fabs(dy)<=0.01*tmod )
			dy = 0;
		if( hasColl )
			checkLifters();
    }
}