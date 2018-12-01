import mt.heaps.slib.*;
import mt.deepnight.Sfx;

class Assets {
	// public static var SFX = Sfx.importDirectory("sfx");
	// public static var MUS = Sfx.importDirectory("music");
	// public static var tiles : SpriteLib;
	public static var font : h2d.Font;

	static var initDone = false;
	public static function init() {
		if( initDone )
			return;
		initDone = true;

		font = hxd.Res.minecraftiaOutline.toFont();

		// Sound init
		Sfx.setGroupVolume(0, 1);
		Sfx.setGroupVolume(1, 0.5);
		#if debug
		// Sfx.toggleMuteGroup(1);
		#end

		// tiles = mt.heaps.slib.assets.Atlas.load("tiles.atlas");
		// tiles.defineAnim("heroAimShoot","0(10), 1(10)");
	}
}