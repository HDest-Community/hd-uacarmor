const HDCONST_CORPORATEARMOUR=40;

class HDCorporateArmour : HDMagAmmo {
	default {
		+Inventory.INVBAR
		+HDPickup.CHEATNOGIVE
		+HDPickup.NOTINPOCKETS
		+Inventory.ISARMOR
		Inventory.amount 1;
		HDMagammo.maxperunit HDCONST_CORPORATEARMOUR;
		HDMagammo.magbulk ENC_GARRISONARMOUR;
		Tag "corporate armour";
		Inventory.icon "ARMEA0";
		Inventory.pickupmessage "Picked up the corporate armour.";
	}
	
	int cooldown;

	override bool IsUsed() {
		return true;
	}

	override int GetSBarNum(int flags) {
		int ms = mags.size() - 1;
		if (ms<0) {
			return -1000000;
		} else {
			return mags[ms]%1000;
		}
	}

	override void AddAMag(int addamt) {
		if (addamt<0) {
			addamt=HDCONST_CORPORATEARMOUR;
		}
		mags.Push(addamt);
		amount = mags.Size();
	}

	override void MaxCheat(){
		SyncAmount();
		for (int i = 0; i < amount; i++) {
			mags[i] = HDCONST_CORPORATEARMOUR;
		}
	}

	action void A_WearArmour() {
		bool helptext = (!!player && CVar.GetCvar("hd_helptext", player).GetBool());
		invoker.SyncAmount();
		int dbl = invoker.mags[invoker.mags.Size() - 1];
		//if holding use, cycle to next armour
		if (!!player && player.cmd.buttons & BT_USE) {
			invoker.mags.Insert(0, dbl);
			invoker.mags.Pop();
			invoker.SyncAmount();
			return;
		}

		let oaw=HDArmourWorn(findinventory("HDArmourWorn"));
		let ocaw=HDArmourWorn(findinventory("HDCorporateArmourWorn"));

		invoker.wornlayer=STRIP_ARMOUR+1;
		bool intervening=!HDPlayerPawn.CheckStrip(self,invoker,false);
		invoker.wornlayer=0;

		if(intervening){
			invoker.wornlayer=STRIP_ARMOUR;
			HDPlayerPawn.CheckStrip(self,invoker);
			invoker.wornlayer=0;
			return;
		}else if(oaw){
			if(invoker.cooldown>0){
				dropinventory(oaw);
				A_Log("Removing "..oaw.gettag().." first.",true);
			}else invoker.cooldown=10;
			return;
		}else if(ocaw){
			if(invoker.cooldown>0){
				dropinventory(ocaw);
				A_Log("Removing "..ocaw.gettag().." first.",true);
			}else invoker.cooldown=10;
			return;
		}

		//and finally put on the actual armour
		HDArmour.ArmourChangeEffect(self);
		let worn = HDArmourWorn(GiveInventoryType("HDCorporateArmourWorn"));
		worn.durability = dbl;
		invoker.amount--;
		invoker.mags.Pop();

		if (helptext) {
			string blah = string.Format("You put on the corporate armor. ");
			double qual = double(worn.durability) / HDCONST_CORPORATEARMOUR;
			if (qual < 0.2) A_Log(blah.."Just don't get hit.", true);
			else if (qual < 0.3) A_Log(blah.."You cover your shameful nakedness with your filthy rags.", true);
			else if (qual < 0.5) A_Log(blah.."It's better than nothing.", true);
			else if (qual < 0.7) A_Log(blah.."This armour has definitely seen better days.", true);
			else if (qual < 0.9) A_Log(blah.."This armour does not pass certification.", true);
			else A_Log(blah, true);
		}

		invoker.SyncAmount();
	}

	override void DoEffect(){
		if (cooldown>0) {
			cooldown--;
		}
		if (!amount) {
			Destroy();
		}
	}

	override void ActualPickup(actor other,bool silent){
		cooldown = 0;
		if (!other) {
			return;
		}
		int durability = mags[mags.Size() - 1];
		//put on the armour right away
		if (
			other.player && other.player.cmd.buttons & BT_USE &&
			!other.FindInventory("HDArmourWorn") && !other.FindInventory("HDCorporateArmourWorn") &&
			HDPlayerPawn(other).striptime == 0
		) {
			HDArmour.ArmourChangeEffect(other);
			let worn = HDArmourWorn(other.GiveInventoryType("HDCorporateArmourWorn"));
			worn.durability = durability;
			Destroy();
			return;
		}
		if(!trypickup(other))return;
		HDCorporateArmour aaa = HDCorporateArmour(other.findinventory("HDCorporateArmour"));
		aaa.SyncAmount();
		aaa.mags.Insert(0, durability);
		aaa.mags.Pop();
		other.A_StartSound(pickupsound, CHAN_AUTO);
		other.A_Log(string.Format("\cg%s", PickupMessage()), true);
	}

	override void BeginPlay(){
		cooldown = 0;
		Super.BeginPlay();
	}

	override void Consolidate() {}

	override double GetBulk(){
		SyncAmount();
		double blk = 0;
		for (int i = 0; i < amount; i++) {
			blk += ENC_GARRISONARMOUR;
		}
		return blk;
	}

	override void SyncAmount() {
		if (amount<1) {
			Destroy();
			return;
		}
		Super.SyncAmount();
		icon = TexMan.CheckForTexture("ARMEA0", TexMan.Type_MiscPatch);
		for (int i = 0; i < amount; i++) {
			mags[i] = Min(mags[i], HDCONST_CORPORATEARMOUR);
		}
	}

	States {
		Spawn:
			ARME A -1;
			stop;
		Use:
			TNT1 A 0 A_WearArmour();
			fail;
	}
}

class HDCorporateArmourWorn : HDArmourWorn {
	default {
		HDPickup.refid "awc";
		Tag "corporate armour";
	}
	
	int counter;
	
	override void BeginPlay() {
		Super.BeginPlay();
		durability = HDCONST_CORPORATEARMOUR;
	}
	
	override void Tick() {
		Super.Tick();
		counter++;
		if(counter%140==0 && durability<HDCONST_CORPORATEARMOUR){
			int repairchance=durability/10;
			int repairamtmax=repairchance;
			if(repairchance<1)repairchance=1;
			if(random(0,20)+(countinv("IsMoving")/10)<=repairchance)durability+=random(1,repairamtmax);
		}
		if(durability>HDCONST_CORPORATEARMOUR)durability=HDCONST_CORPORATEARMOUR;
	}
	
	override inventory CreateTossable(int amt){
		if(!HDPlayerPawn.CheckStrip(owner,self))return null;

		//armour sometimes crumbles into dust
		if(durability<random(1,3)){
			for(int i=0;i<10;i++){
				actor aaa=spawn("WallChunk",owner.pos+(0,0,owner.height-24),ALLOW_REPLACE);
				vector3 offspos=(frandom(-12,12),frandom(-12,12),frandom(-16,4));
				aaa.setorigin(aaa.pos+offspos,false);
				aaa.vel=owner.vel+offspos*frandom(0.3,0.6);
				aaa.scale*=frandom(0.8,2.);
			}
			destroy();
			return null;
		}

		//finally actually take off the armour
		HDArmour.ArmourChangeEffect(owner,90);
		let tossed=HDCorporateArmour(owner.spawn("HDCorporateArmour",
			(owner.pos.x,owner.pos.y,owner.pos.z+owner.height-20),
			ALLOW_REPLACE
		));
		tossed.mags.clear();
		tossed.mags.push(durability);
		tossed.amount=1;
		destroy();
		return tossed;
	}
	
	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,int,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		int towound,
		int toburn,
		int tostun,
		int tobreak
	){
		let victim=owner;

		//approximation of "thickness" of armour
		int alv=3;

		if(
			(flags&DMG_NO_ARMOR)
			||mod=="staples"
			||mod=="maxhpdrain"
			||mod=="internal"
			||mod=="jointlock"
			||mod=="falling"
			||mod=="bleedout"
			||mod=="invisiblebleedout"
			||mod=="drowning"
			||mod=="poison"
			||durability<random(1,8) //it just goes through a gaping hole in your armour
			||!victim
		)return damage,mod,flags,towound,toburn,tostun,tobreak;


		//which is just a vest not a bubble...
		if(
			inflictor
			&&inflictor.default.bmissile
		){
			double impactheight=inflictor.pos.z+inflictor.height*0.5;
			double shoulderheight=victim.pos.z+victim.height-16;
			double waistheight=victim.pos.z+victim.height*0.4;
			double impactangle=absangle(victim.angle,victim.angleto(inflictor));
			if(impactangle>90)impactangle=180-impactangle;
			bool shouldhitflesh=(
				impactheight>shoulderheight
				||impactheight<waistheight
				||impactangle>80
			)?!random(0,5):!random(0,31);
			if(shouldhitflesh)alv=0;
			else if(impactangle>80)alv=random(1,alv);
		}

		//missed the armour entirely
		if(alv<1)return damage,mod,flags,towound,toburn,tostun,tobreak;


		//some numbers
		int tobash=0;
		int armourdamage=0;

		int resist=0;
		if(durability<HDCONST_CORPORATEARMOUR){
			int breakage=HDCONST_CORPORATEARMOUR-durability;
			resist-=random(0,breakage);
		}

		int originaldamage=damage;


		//start treating damage types
		if(mod=="slime"){
			victim.A_SetInventory("Heat",countinv("Heat")+max(0,damage-random(4,20)));
			damage=0;
		}else if(
			mod=="hot"
			||mod=="cold"
		){
			if(damage<random(0,21))damage=0;
			else{
				int olddamage=damage>>1;
				damage=olddamage>>2;
				if(!damage&&random(0,olddamage))damage=1;
			}
		}else if(mod=="electrical"){
			int olddamage=damage>>2;
			damage=olddamage>>3;
			if(!damage&&random(0,olddamage))damage=1;
		}else if(mod=="piercing"){
			resist+=30*(alv+1);
			if(resist>0){
				damage-=resist;
				tobash=min(originaldamage,resist)>>3;
			}
			armourdamage=random(0,originaldamage>>2);
		}else if(mod=="slashing"){
			resist+=100+25*alv;
			if(resist>0){
				damage-=resist;
				tobash=min(originaldamage,resist)>>2;
			}
			armourdamage=random(0,originaldamage>>2);
		}else if(
			mod=="teeth"
			||mod=="claws"
			||mod=="natural"
		){
			resist+=random((alv<<4),100+50*alv);
			if(resist>0){
				damage-=resist;
				tobash=min(originaldamage,resist)>>3;
			}
			armourdamage=random(0,originaldamage>>3);
		}else if(
			mod=="balefire"
		){
			if(random(0,alv)){
				towound-=max(1,damage>>2);
				armourdamage=random(0,damage>>2);
			}
		}else if(
			mod=="bashing"
			||mod=="melee"
		){
			armourdamage=clamp((originaldamage>>3),0,random(0,alv));

			//player punch to head
			bool headshot=inflictor&&(
				(
					inflictor.player
					&&inflictor.pitch<-3.2
				)||(
					HDHumanoid(inflictor)
					&&damage>50
				)
			);
			if(!headshot){
				damage=int(damage*(1.-(alv*0.1)));
			}
		}else{
			//any other damage not taken care of above
			resist+=50*alv;
			if(resist>0){
				damage-=resist;
				tobash=min(originaldamage,resist)>>random(0,2);
			}
			armourdamage=random(0,originaldamage>>random(1,3));
		}



		if(hd_debug)console.printf(owner.gettag().."  took "..originaldamage.." "..mod.." from "..(source?source.gettag():"the world")..(inflictor?("'s "..inflictor.gettag()):"").."  converted "..tobash.."  final "..damage.."   lost "..armourdamage);


		//set up attack position for puff and knockback
		vector3 puffpos=victim.pos;
		if(
			inflictor
			&&inflictor!=source
		)puffpos=inflictor.pos;
		else if(
			source
			&&source.pos.xy!=victim.pos.xy
		)puffpos=(
			victim.pos.xy+victim.radius*(source.pos.xy-victim.pos.xy).unit()
			,victim.pos.z+min(victim.height,source.height*0.6)
		);
		else puffpos=(victim.pos.xy,victim.pos.z+victim.height*0.6);

		//add some knockback even when target unhurt
		if(
			damage<1
			&&tobash<1
			&&victim.health>0
			&&victim.height>victim.radius*1.6
			&&victim.pos!=puffpos
		){
			victim.vel+=(victim.pos-puffpos).unit()*0.01*originaldamage;
			let hdp=hdplayerpawn(victim);
			if(
				hdp
				&&!hdp.incapacitated
			){
				hdp.hudbobrecoil2+=(frandom(-5.,5.),frandom(2.5,4.))*0.01*originaldamage;
				hdp.playrunning();
			}else if(random(0,255)<victim.painchance)hdmobbase.forcepain(victim);
		}

		//armour breaks up visibly
		if(armourdamage>3){
			actor ppp=spawn("FragPuff",puffpos);
			ppp.vel+=victim.vel;
		}
		if(armourdamage>random(0,2)){
			vector3 prnd=(frandom(-1,1),frandom(-1,1),frandom(-1,1));
			actor ppp=spawn("WallChunk",puffpos+prnd);
			ppp.vel+=victim.vel+(puffpos-owner.pos).unit()*3+prnd;
		}


		//apply stuff
		if(tobash>0)victim.damagemobj(
			inflictor,source,min(tobash,victim.health-1),
			mod,DMG_NO_ARMOR|DMG_THRUSTLESS
		);

		if(armourdamage>0)durability-=armourdamage;
		if(durability<1)destroy();

		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}
	
	//called from HDBulletActor's OnHitActor
	override double,double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penshell,
		double hitangle,
		double deemedwidth,
		vector3 hitpos,
		vector3 vu,
		bool hitactoristall
	){
		let hitactor=owner;
		if(!owner)return 0,0;
		let hdp=HDPlayerPawn(hitactor);
		let hdmb=HDMobBase(hitactor);

		//if standing right over an incap'd victim, bypass armour
		if(
			bullet.pitch>80
			&&(
				(hdp&&hdp.incapacitated)
				||(
					hdmb
					&&hdmb.frame>=hdmb.downedframe
					&&hdmb.instatesequence(hdmb.curstate,hdmb.resolvestate("falldown"))
				)
			)
			&&!!bullet.target
			&&abs(bullet.target.pos.z-bullet.pos.z)<bullet.target.height
		)return pen,penshell;

		double hitheight=hitactoristall?((hitpos.z-hitactor.pos.z)/hitactor.height):0.5;

		double addpenshell=40;

		//poorer armour on legs and head
		//sometimes slip through a gap
		int crackseed=int(level.time+angle)&(1|2|4|8|16|32);
		if(hitheight>0.8){
			if(
				(hdmb&&!hdmb.bhashelmet)
//				||(hdp&&!hdp.bhashelmet)
			)addpenshell=-1;else{
				//face?
				if(
					crackseed>clamp(durability,1,3)
					&&absangle(bullet.angle,hitactor.angle)>(180.-5.)
					&&bullet.pitch>-20
					&&bullet.pitch<7
				)addpenshell*=frandom(0.1,0.9);else
				//head: thinner material required
				addpenshell=min(addpenshell,frandom(10,20));
			}
		}else if(hitheight<0.4){
			//legs: gaps and thinner (but not that much thinner) material
			if(crackseed>clamp(durability,1,8))
				addpenshell*=frandom(frandom(0,0.9),1.);
		}else if(
			crackseed>max(durability,8)
		){
			//torso: just kinda uneven
			addpenshell*=frandom(0.8,1.1);
		}

		int armourdamage=0;


		if(addpenshell>0){
			//degrade and puff
			armourdamage=random(-1,(int(min(pen,addpenshell)*bullet.stamina)>>12));
			if(armourdamage>0){
				actor p=spawn(armourdamage>2?"FragPuff":"WallChunk",bullet.pos,ALLOW_REPLACE);
				if(p)p.vel=hitactor.vel-vu*2+(frandom(-1,1),frandom(-1,1),frandom(-1,3));
			}else if(pen>addpenshell)armourdamage=1;
		}else if(addpenshell>-0.5){
			//bullet leaves a hole in the webbing
			armourdamage+=max(random(0,1),(bullet.stamina>>7));
		}
		else if(hd_debug)console.printf("missed the armour!");

		if(hd_debug)console.printf(hitactor.getclassname().."  armour resistance:  "..addpenshell);
		penshell+=addpenshell;


		//add some knockback even when target unhurt
		if(
			pen>2
			&&penshell>pen
			&&hitactor.health>0
			&&hitactoristall
		){
			hitactor.vel+=vu*0.001*hitheight*mass;
			if(
				hdp
				&&!hdp.incapacitated
			){
				hdp.hudbobrecoil2+=(frandom(-5.,5.),frandom(2.5,4.))*0.01*hitheight*mass;
				hdp.playrunning();
			}else if(random(0,255)<hitactor.painchance) hdmobbase.forcepain(hitactor);
		}


	if(armourdamage>0)durability-=armourdamage;
		if(durability<1)destroy();

		return pen,penshell;
	}
}

class CorporateArmour : HDPickupGiver {
	default {
		//$Category "Items/Hideous Destructor"
		//$Title "Corporate Armour"
		//$Sprite "ARMEA0"
		+missilemore
		+hdpickup.fitsinbackpack
		+inventory.isarmor
		inventory.icon "ARMEA0";
		hdpickupgiver.pickuptogive "HDCorporateArmour";
		hdpickup.bulk ENC_GARRISONARMOUR;
		hdpickup.refid "arc";
		tag "corporate armour (spare)";
		inventory.pickupmessage "Picked up the corporate armour.";
	}
	
	override void configureactualpickup() {
		let aaa=HDCorporateArmour(actualitem);
		aaa.mags.clear();
		aaa.mags.push(HDCONST_CORPORATEARMOUR);
		aaa.syncamount();
	}
}
