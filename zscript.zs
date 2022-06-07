version "4.7"

#include "zscript/corpoarmour.zs"

class UACArmourHandler : EventHandler {
    override void CheckReplacement(ReplaceEvent e) {
        if(!e.Replacement) return;

        switch(e.Replacement.GetClassName()) {
            case 'BattleArmour':
                if(random[uacrand]() <= 24) e.Replacement = "HDCorporateArmour";
                break;
            case 'GarrisonArmour':
                if (random[uacrand]() <= 12) e.Replacement = "HDCorporateArmour";
                break;
        }
    }
}
