package org.pigtracerlab {

  import flash.display.Sprite;
  import flash.events.Event;
  //import controls.Btn;

  [SWF(backgroundColor="#000000", width="600", height="340", frameRate="40")]
  public class APNG extends Sprite {
    [Embed(source="apng.png", mimeType="application/octet-stream")]
    private var png:Class;
    private var player:APNGPlayer;

    public function APNG() {
      init();
    }
    private function init():void {
      
      player = new APNGPlayer();
      addChild(player);
      
      player.addEventListener(APNGPlayer.APNG_LOADED, loaded, false, 0, true);
      player.asset(png);
      
      //or player.load("file");
    }
    private function loaded(evt:Event):void {
      player.removeEventListener(APNGPlayer.APNG_LOADED, loaded);
      player.play();
    }
  }
}