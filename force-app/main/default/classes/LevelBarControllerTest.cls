/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         29/02/2012
* Description:  TEST CLASS: LevelBarController
*
* ------------------
* TESTING:		100%
* ------------------
*       
**/
@isTest
private class LevelBarControllerTest {

    static testMethod void levelBarGenericTest() {
        LevelBarController range1 = new LevelBarController();
        range1.levelNum = '20';
        range1.getColorBar();
        range1.getCursorLeft();
        range1.getTextAreaLeft();
        LevelBarController range2 = new LevelBarController();
        range2.levelNum = '40';
        range2.getColorBar();
        range2.getCursorLeft();
        LevelBarController range3 = new LevelBarController();
        range3.levelNum = '60';
        range3.getColorBar();
        range3.getCursorLeft();
        LevelBarController range4 = new LevelBarController();
        range4.levelNum = '90';
        range4.getColorBar();
        range4.getCursorLeft();
    }
}