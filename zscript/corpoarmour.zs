const HDCONST_CORPORATEARMOUR=40;
const ENC_CORPORATEARMOUR=530;

class HDCorporateArmour : HDArmour {
	default {
		Tag "$TAG_CORPORATEARMOUR";

		Inventory.icon "CARMA0";
		Inventory.pickupmessage "$PICKUP_CORPORATEARMOUR";

		HDMagammo.maxperunit HDCONST_CORPORATEARMOUR;
		HDMagammo.magbulk ENC_CORPORATEARMOUR;
	}

	override void Tick() {
		super.Tick();

		if (durability < HDCONST_CORPORATEARMOUR && !(Level.time % (TICRATE * 4))) durability += random(0, 1);
	}

	override WearArmourHelpText(Actor wearer, double durability) {
		if (!HDWeapon.CheckDoHelpText(wearer)) return;

		string opinion = "";
		double qual = durability / maxperunit;
		if (qual < 0.2)       opinion = "$CORPORATEARMOUR_DURABILITY_2";
		else if (qual < 0.3)  opinion = "$CORPORATEARMOUR_DURABILITY_3";
		else if (qual < 0.6)  opinion = "$CORPORATEARMOUR_DURABILITY_6";
		else if (qual < 0.75) opinion = "$CORPORATEARMOUR_DURABILITY_75";
		else if (qual < 0.95) opinion = "$CORPORATEARMOUR_DURABILITY_95";

		wearer.A_Log(
			Stringtable.Localize("$ARMOUR_PUTON")
			..gettag()
			..Stringtable.Localize("$HD_SENTENCEBREAK")
			..Stringtable.Localize(opinion)
		,true);
	}

	States {
		Spawn:
			CARM A -1;
			stop;
	}
}

class HDCorporateArmourWorn : HDArmourWorn {

	default {
		Tag "$TAG_CORPORATEARMOUR";

		HDPickup.bulk ENC_CORPORATEARMOUR * 0.1;
		HDPickup.refid "awu";

		HDArmourWorn.armoursprite "CARMA0";
		HDArmourWorn.armourback "CARMB0";

		HDArmourWorn.durability HDCONST_CORPORATEARMOUR;
		HDArmourWorn.hindrance 2.35;
		HDArmourWorn.thickness 3;
	}

	override void Tick() {
		super.Tick();

		if (durability < HDCONST_CORPORATEARMOUR && !(Level.time % (TICRATE * 4))) durability += random(0, 1);
	}

	override void DetachFromOwner() {
		super.DetachFromOwner();

		owner.A_TakeInventory("HDFireDouse", 20);
	}
	
	override void DoEffect() {
		super.DoEffect();

		HDF.Give(owner, "HDFireDouse", 20);
		owner.A_TakeInventory("Heat");
	}

	override void Consolidate() {
		super.Consolidate();

		// Fully repairs during downtime
		durability = HDCONST_CORPORATEARMOUR;
	}

	override int,int,double,int,int,int,int,int HandleDamageType(
		name mod,
		int alv,
		int damage,
		int armourdamage,
		double towound,
		int tobash,
		int toburn,
		int tostun,
		int tobreak,
		int resist
	) {
		switch (mod) {
			case 'slime':
				resist += 10 * (alv + 1);
				if (resist > 0) {
					damage -= resist;
					toburn = min(originaldamage, resist) >> 1;
				}
				break;
			case 'hot':
			case 'cold':
			case 'balefire':
				resist += 10 * (alv + 1);
				if (resist > 0) {
					toburn = min(originaldamage, resist) >> 3;
					if (damage > 21) {
						int olddamage = damage >> 2;
						damage = olddamage >> 3;
						if (!damage && random(0, olddamage)) damage = 1;
						armourdamage = random(0, originaldamage >> 2);
					} else {
						damage = 0;
					}
				}
				break;
			case 'electrical':
				resist += 10 * (alv + 1);
				if (resist > 0) {
					toburn = min(originaldamage, resist) >> 3;
					if (damage > 60) {
						int olddamage = damage >> 1;
						damage = olddamage >> 2;
						if (!damage && random(0, olddamage))damage = 1;
						armourdamage = random(0, originaldamage >> 1);
					} else {
						damage = 0;
					}
				}
				break;
			default:
				return super.HandleDamageType(mod, alv, damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist);
		}

		return damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist;
	}
}
