//-------------------------------------------------
// Armour
//-------------------------------------------------
const HDCONST_BATTLEARMOUR=70;
const HDCONST_GARRISONARMOUR=144;

class HDArmour:HDMagAmmo{
	default{
		+inventory.invbar
		+hdpickup.cheatnogive
		+hdpickup.notinpockets
		+inventory.isarmor
		inventory.amount 1;
		hdmagammo.maxperunit (HDCONST_BATTLEARMOUR+1000);
		hdmagammo.magbulk ENC_GARRISONARMOUR;
		tag "armour";
		inventory.icon "ARMSB0";
		inventory.pickupmessage "Picked up the garrison armour.";
	}
	bool mega;
	int cooldown;
	override bool isused(){return true;}
	override int getsbarnum(int flags){
		int ms=mags.size()-1;
		if(ms<0)return -1000000;
		return mags[ms]%1000;
	}
	override string pickupmessage(){
		if(mags[mags.size()-1]>=1000)return "Picked up the battle armour!";
		return super.pickupmessage();
	}
	//because it can intentionally go over the maxperunit amount
	override void AddAMag(int addamt){
		if(addamt<0)addamt=HDCONST_GARRISONARMOUR;
		mags.push(addamt);
		amount=mags.size();
	}
	//keep types the same when maxing
	override void MaxCheat(){
		syncamount();
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)mags[i]=(HDCONST_BATTLEARMOUR+1000);
			else mags[i]=HDCONST_GARRISONARMOUR;
		}
	}
	action void A_WearArmour(){
		bool helptext=!!player&&cvar.getcvar("hd_helptext",player).getbool();
		invoker.syncamount();
		int dbl=invoker.mags[invoker.mags.size()-1];
		//if holding use, cycle to next armour
		if(!!player&&player.cmd.buttons&BT_USE){
			invoker.mags.insert(0,dbl);
			invoker.mags.pop();
			invoker.syncamount();
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
		HDArmour.ArmourChangeEffect(self,100);
		A_GiveInventory("HDArmourWorn");
		let worn=HDArmourWorn(FindInventory("HDArmourWorn"));
		if(dbl>=1000){
			dbl-=1000;
			worn.mega=true;
		}
		worn.durability=dbl;
		invoker.amount--;
		invoker.mags.pop();

		if(helptext){
			string blah=string.format("You put on the %s armour. ",worn.mega?"battle":"garrison");
			double qual=double(worn.durability)/(worn.mega?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR);
			if(qual<0.1)A_Log(blah.."Just don't get hit.",true);
			else if(qual<0.3)A_Log(blah.."You cover your shameful nakedness with your filthy rags.",true);
			else if(qual<0.6)A_Log(blah.."It's better than nothing.",true);
			else if(qual<0.75)A_Log(blah.."This armour has definitely seen better days.",true);
			else if(qual<0.95)A_Log(blah.."This armour does not pass certification.",true);
		}

		invoker.syncamount();
	}
	override void doeffect(){
		if(cooldown>0)cooldown--;
		if(!amount)destroy();
	}
	override void syncamount(){
		if(amount<1){destroy();return;}
		super.syncamount();
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)mags[i]=max(mags[i],1001);
			else mags[i]=min(mags[i],HDCONST_GARRISONARMOUR);
		}
		checkmega();
	}
	override inventory createtossable(int amt){
		let sct=super.createtossable(amt);
		if(self)checkmega();
		return sct;
	}
	bool checkmega(){
		mega=mags.size()&&mags[mags.size()-1]>1000;
		icon=texman.checkfortexture(mega?"ARMCB0":"ARMSB0",TexMan.Type_MiscPatch);
		return mega;
	}
	override void beginplay(){
		cooldown=0;
		mega=icon==texman.checkfortexture("ARMCB0",TexMan.Type_MiscPatch);
		mags.push((mega?(1000+HDCONST_BATTLEARMOUR):HDCONST_GARRISONARMOUR));
		super.beginplay();
	}
	override void consolidate(){}
	override double getbulk(){
		syncamount();
		checkmega();
		double blk=0;
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)blk+=ENC_BATTLEARMOUR;
			else blk+=ENC_GARRISONARMOUR;
		}
		return blk;
	}
	override bool BeforePockets(actor other){
		//put on the armour right away
		if(
			other.player
			&&other.player.cmd.buttons&BT_USE
			&&!other.findinventory("HDArmourWorn")
			&&!other.findinventory("HDCorporateArmourWorn")
		){
			wornlayer=STRIP_ARMOUR;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			HDArmour.ArmourChangeEffect(other,110);
			let worn=HDArmourWorn(other.GiveInventoryType("HDArmourWorn"));
			int durability=mags[mags.size()-1];
			if(durability>=1000){
				durability-=1000;
				worn.mega=true;
			}
			worn.durability=durability;
			destroy();
			return true;
		}
		return false;
	}
	override void actualpickup(actor other,bool silent){
		cooldown=0;
		if(!other)return;
		int durability=mags[mags.size()-1];
		HDArmour aaa=HDArmour(other.findinventory("HDArmour"));

		//one megaarmour = 2 regular armour
		if(aaa){
			double totalbulk=(durability>=1000)?2.:1.;
			for(int i=0;i<aaa.mags.size();i++){
				totalbulk+=(aaa.mags[i]>=1000)?2.:1.;
			}
			if(totalbulk*hdmath.getencumbrancemult()>3.)return;
		}
		if(!trypickup(other))return;
		aaa=HDArmour(other.findinventory("HDArmour"));
		aaa.syncamount();
		aaa.mags.insert(0,durability);
		aaa.mags.pop();
		aaa.checkmega();
		other.A_StartSound(pickupsound,CHAN_AUTO);
		other.A_Log(string.format("\cg%s",pickupmessage()),true);
	}
	static void ArmourChangeEffect(actor owner,int delay=25){
		owner.A_StartSound("weapons/pocket",CHAN_BODY);
		owner.A_ChangeVelocity(0,0,2);
		let onr=HDPlayerPawn(owner);
		if(onr){
			onr.stunned+=90;
			onr.striptime=delay;
			onr.AddBlackout(256,96,128);
		}else owner.A_SetBlend("00 00 00",1,6,"00 00 00");
	}
	states{
	spawn:
		ARMS A -1 nodelay A_JumpIf(invoker.mega,1);
		ARMC A -1;
		stop;
	use:
		TNT1 A 0 A_WearArmour();
		fail;
	}
}


class HDArmourWorn:HDDamageHandler{
	int durability;
	bool mega;property ismega:mega;
	default{
		+inventory.isarmor
		HDArmourworn.ismega false;
		inventory.maxamount 1;
		tag "garrison armour";
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_ARMOUR;
	}
	override void beginplay(){
		durability=mega?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR;
		super.beginplay();
		if(mega)settag("battle armour");
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(mega)settag("battle armour");
	}
	override void RestrictSpeed(out double maxspeed){
		maxspeed=min(maxspeed,mega?2.:3.);
	}
	override double getbulk(){
		return mega?(ENC_BATTLEARMOUR*0.16):(ENC_GARRISONARMOUR*0.1);
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
		let tossed=HDArmour(owner.spawn("HDArmour",
			(owner.pos.x,owner.pos.y,owner.pos.z+owner.height-20),
			ALLOW_REPLACE
		));
		tossed.mags.clear();
		tossed.mags.push(mega?durability+1000:durability);
		tossed.amount=1;
		destroy();
		return tossed;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
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
		int alv=mega?3:1;

		if(
			(flags&DMG_NO_ARMOR)
			||mod=="staples"
			||mod=="maxhpdrain"
			||mod=="internal"
			||mod=="jointlock"
			||mod=="falling"
			||mod=="slime"
			||mod=="bleedout"
			||mod=="invisiblebleedout"
			||mod=="drowning"
			||mod=="poison"
			||mod=="electrical"
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
		if(durability<HDCONST_BATTLEARMOUR){
			int breakage=HDCONST_BATTLEARMOUR-durability;
			resist-=random(0,breakage);
		}

		int originaldamage=damage;


		//start treating damage types
		if(
			mod=="hot"
			||mod=="cold"
		){
			if(random(0,alv)){
				damage=max(random(0,1-random(0,alv)),damage-30);
				if(!random(0,200-damage))armourdamage+=(damage>>3);
			}
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

		double addpenshell=mega?30:(10+max(0,((durability-120)>>3)));

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



class BattleArmour:HDPickupGiver replaces BlueArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Battle Armour"
		//$Sprite "ARMCA0"
		+missilemore
		+hdpickup.fitsinbackpack
		+inventory.isarmor
		inventory.icon "ARMCA0";
		hdpickupgiver.pickuptogive "HDArmour";
		hdpickup.bulk ENC_BATTLEARMOUR;
		hdpickup.refid HDLD_ARMB;
		tag "battle armour (spare)";
		inventory.pickupmessage "Picked up the battle armour.";
	}
	override void configureactualpickup(){
		let aaa=HDArmour(actualitem);
		aaa.mags.clear();
		aaa.mags.push(bmissilemore?(1000+HDCONST_BATTLEARMOUR):HDCONST_GARRISONARMOUR);
		aaa.syncamount();
	}
}
class GarrisonArmour:BattleArmour replaces GreenArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Garrison Armour"
		//$Sprite "ARMSA0"
		-missilemore
		inventory.icon "ARMSA0";
		hdpickup.bulk ENC_GARRISONARMOUR;
		hdpickup.refid HDLD_ARMG;
		tag "garrison armour (spare)";
		inventory.pickupmessage "Picked up the garrison armour.";
	}
}


class BattleArmourWorn:HDPickup{
	default{
		+missilemore
		-hdpickup.fitsinbackpack
		+inventory.isarmor
		hdpickup.refid HDLD_ARWB;
		tag "battle armour";
		inventory.maxamount 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(owner){
			owner.A_GiveInventory("HDArmourWorn");
			let ga=HDArmourWorn(owner.findinventory("HDArmourWorn"));
			ga.durability=(bmissilemore?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR);
			ga.mega=bmissilemore;
		}
		destroy();
	}
}
class GarrisonArmourWorn:BattleArmourWorn{
	default{
		-missilemore
		-hdpickup.fitsinbackpack
		inventory.icon "ARMCB0";
		hdpickup.refid HDLD_ARWG;
		tag "garrison armour";
	}
}

