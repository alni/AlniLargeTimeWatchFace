/**
 * https://gist.github.com/somethingkindawierd/512b01bbcb6cd8f50a02e12cb74972f8
 */

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

function clamp(value, max, min) {
   if(value > max) {
	   return max;
   }
   else if(value < min) {
	   return min;
   }
   return value;
}

class ProgressBar extends Ui.Drawable {

    hidden var color, locX, locY, width, height, percentage;

    function initialize(params) {
        Drawable.initialize(params);

        color = params.get(:color);
        locX = params.get(:locX);
        locY = params.get(:locY);
        width = params.get(:width);
        height = params.get(:height);
        percentage = 0.0;
    }

    function setPercent(value) {
        percentage = clamp(value, 1.0, 0.0);
    }

    function setColor(value) {
    	color = value;
    }

    function draw(dc) {
        //dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_LT_GRAY);
        //dc.drawRectangle(locX, locY, width, height);
        dc.setColor(color, color);
        //dc.fillRectangle(locX + 2, locY + 2, (width - 4) * percentage, height - 4);
        dc.fillRectangle(locX, locY, width * percentage, height);
    }
}
