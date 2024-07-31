using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics as Gfx;

class Background extends Ui.Drawable {

    hidden static const DEFAULT_BG_COLOR = Gfx.COLOR_BLACK;
    hidden var bgColor = Gfx.COLOR_BLACK;

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };
        
        self.bgColor = DEFAULT_BG_COLOR;

        Drawable.initialize(dictionary);
    }

    function setBgColor(bgColor) {
        if (bgColor != null) {
            self.bgColor = bgColor;
        } else {
            self.bgColor = App.Properties.getValue("BackgroundColor");
        }

        if (self.bgColor == null) {
            self.bgColor = DEFAULT_BG_COLOR;
        }
    }

    function draw(dc) {
        // Set the background color then call to clear the screen
        dc.setColor(Gfx.COLOR_TRANSPARENT, self.bgColor);
        dc.clear();
    }

}
