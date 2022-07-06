/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         21/02/2012
* Description:  Component controller for displaying a progressbar.
*
*       
**/
public with sharing class LevelBarController {
    
    public String levelNum {get; set;}
    public String cursorLeft = null;
    public String textAreaLeft = null;
    public String colorBar = null;
    
    public String getCursorLeft() {
        if (cursorLeft == null) {
            Integer padding = 0;
            if (Integer.valueOf(levelNum) < 80 && Integer.valueOf(levelNum) > 20) {
                padding = 5;
            } else if (Integer.valueOf(levelNum) <= 20) {
                padding = 10;
            }
            cursorLeft = String.valueOf(((Integer.valueOf(levelNum)*300)/100) - padding);           
        } 

        return cursorLeft;
    }
    
    public String getTextAreaLeft() {
        if (textAreaLeft == null) {
            textAreaLeft = String.valueOf(Integer.valueOf(getCursorLeft()) - 16);       
        } 

        return textAreaLeft;
    }
    
    public String getColorBar() {
        if (colorBar == null) {
            colorBar = 'lbred.png';
            Integer lev = Integer.valueOf(levelNum);
            if (lev >= 25 && lev < 50) {
                colorBar = 'lborange.png';
            } else if (lev >= 50 && lev < 75) {
                colorBar = 'lbyellow.png';
            } else if (lev >= 75) {
                colorBar = 'lbgreen.png';
            }       
        } 

        return colorBar;
    }
    
    public LevelBarController() {
        //cursorLeft = String.valueOf((Integer.valueOf(levelNum)*300)/100);
    }
}