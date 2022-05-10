const HDCONST_CORPORATEARMOUR=40;
const ENC_CORPORATEARMOUR=530;

class HDCorporateArmour : HDMagAmmo {
	default {
		+Inventory.INVBAR
		+HDPickup.CHEATNOGIVE
		+HDPickup.NOTINPOCKETS
		+Inventory.ISARMOR
		Inventory.amount 1;
		HDMagammo.maxperunit HDCONST_CORPORATEARMOUR;
		HDMagammo.magbulk ENC_CORPORATEARMOUR;
		Tag "corporate armour";
		Inventory.icon "CARMA0";
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

		invoker.wornlayer=STRIP_ARMOUR;
		bool intervening=!HDPlayerPawn.CheckStrip(self,invoker,false);
		invoker.wornlayer=0;

		if(intervening){
			//check if it's ONLY the armour layer that's in the way
			invoker.wornlayer=STRIP_ARMOUR+1;
			bool notarmour=!HDPlayerPawn.CheckStrip(self,invoker,false);
			invoker.wornlayer=0;

			if(
				notarmour
				||invoker.cooldown>0
			){
				HDPlayerPawn.CheckStrip(self,self);
			}else invoker.cooldown=10;
			return;
		}

		//and finally put on the actual armour
		HDArmour.ArmourChangeEffect(self,100);
		A_GiveInventory("HDCorporateArmourWorn");
		let worn = HDCorporateArmourWorn(FindInventory("HDCorporateArmourWorn"));
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

	override bool BeforePockets(actor other){
		//put on the armour right away
		if(
			other.player
			&&other.player.cmd.buttons&BT_USE
			&&!other.findinventory("HDCorporateArmourWorn")
		){
			wornlayer=STRIP_ARMOUR;
			bool intervening=!HDPlayerPawn.CheckStrip(other,self,false);
			wornlayer=0;

			if(intervening)return false;

			HDArmour.ArmourChangeEffect(other,110);
			let worn=HDCorporateArmourWorn(other.GiveInventoryType("HDCorporateArmourWorn"));
			int durability=mags[mags.size()-1];
			worn.durability=durability;
			destroy();
			return true;
		}
		return false;
	}

	override void ActualPickup(actor other,bool silent){
		cooldown=0;
		if(!other)return;
		int durability=mags[mags.size()-1];
		if(!trypickup(other))return;
		HDCorporateArmour aaa=HDCorporateArmour(other.findinventory("HDCorporateArmour"));
		aaa.syncamount();
		aaa.mags.insert(0,durability);
		aaa.mags.pop();
		other.A_StartSound(pickupsound,CHAN_AUTO);
		other.A_Log(string.format("\cg%s",pickupmessage()),true);
	}

	override void BeginPlay(){
		cooldown = 0;
		Super.BeginPlay();
	}

	override void Consolidate() {}

	override double GetBulk(){
		return ENC_CORPORATEARMOUR * 0.145;
	}

	override void SyncAmount() {
		if (amount<1) {
			Destroy();
			return;
		}
		Super.SyncAmount();
		icon = TexMan.CheckForTexture("CARMA0", TexMan.Type_MiscPatch);
		for (int i = 0; i < amount; i++) {
			mags[i] = Min(mags[i], HDCONST_CORPORATEARMOUR);
		}
	}

	States {
		Spawn:
			CARM A -1;
			stop;
		Use:
			TNT1 A 0 A_WearArmour();
			fail;
	}
}

class HDCorporateArmourWorn : HDDamageHandler {
	default {
		+inventory.isarmor
		inventory.maxamount 1;
		HDDamageHandler.priority 0;
		HDPickup.wornlayer STRIP_ARMOUR;
		Tag "corporate armour";
	}
	
	int durability;
	int counter;

	override void AttachToOwner(actor other) {
		BecomeItem();
		other.AddInventory(self);

		//in case it's added in a loadout
		if(CheckConflictingWornLayer(owner)){
			amount=0;
			return;
		}
		
		if(overlaypriority){
			let hpl=HDPlayerPawn(owner);
			if(
				hpl
				&&hpl==other
			)hpl.GetOverlayGivers(hpl.OverlayGivers);
		}
	}

	override void DetachFromOwner()
	{
		Super.DetachFromOwner();
		owner.A_TakeInventory("HDFireDouse",20);
	}
	
	override void BeginPlay() {
		Super.BeginPlay();
		durability = HDCONST_CORPORATEARMOUR;
	}

	override void Tick() {
		Super.Tick();
		owner.A_GiveInventory("HDFireDouse",20);
		owner.A_TakeInventory("Heat");
		counter++;
		if(counter%140==0 && durability<HDCONST_CORPORATEARMOUR)durability+=random(0,1);
		if(durability>HDCONST_CORPORATEARMOUR)durability=HDCONST_CORPORATEARMOUR;
	}

	override void Consolidate() {
		durability=HDCONST_CORPORATEARMOUR;
	}

	override double RestrictSpeed(double speedcap){
		return min(speedcap,2.35);
	}

	override double GetBulk(){
		return ENC_CORPORATEARMOUR*0.1;
	}

	override void DrawHudStuff(
		hdstatusbar sb,
		hdplayerpawn hpl,
		int hdflags,
		int gzflags
	){
		vector2 coords=
			(hdflags&HDSB_AUTOMAP)?(4,86):
			(hdflags&HDSB_MUGSHOT)?((sb.hudlevel==1?-85:-55),-4):
			(0,-sb.mIndexFont.mFont.GetHeight()*2)
		;
		string armoursprite="CARMA0";
		string armourback="CARMB0";
		sb.drawbar(
			armoursprite,armourback,
			durability,HDCONST_CORPORATEARMOUR,
			coords,-1,sb.SHADER_VERT,
			gzflags
		);
		sb.drawstring(
			sb.pnewsmallfont,sb.FormatNumber(durability),
			coords+(10,-7),gzflags|sb.DI_ITEM_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_DARKGRAY,scale:(0.5,0.5)
		);
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
		let tossed=HDCorporateArmour(owner.spawn("HDCorporateArmour",
			(owner.pos.x,owner.pos.y,owner.pos.z+owner.height-20),
			ALLOW_REPLACE
		));
		tossed.mags.clear();
		tossed.mags.push(durability);
		tossed.amount=1;
		HDArmour.ArmourChangeEffect(owner,90);
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
			resist+=20*(alv+1);
			if(resist>0){
				damage-=resist;
				toburn=min(originaldamage,resist)>>2;
			}
		}else if(
			mod=="hot"
			||mod=="cold"
			||mod=="balefire"
		){
			resist+=20*(alv+1);
			if(resist>0){
				toburn=min(originaldamage,resist)>>4;
				if(damage>21){
					int olddamage=damage>>3;
					damage=olddamage>>4;
					if(!damage&&random(0,olddamage))damage=1;
					armourdamage=random(0,originaldamage>>3);
				}
				else damage=0;
			}
		}else if(mod=="electrical"){
			resist+=20*(alv+1);
			if(resist>0){
				toburn=min(originaldamage,resist)>>4;
				if(damage>30){
					int olddamage=damage>>1;
					damage=olddamage>>2;
					if(!damage&&random(0,olddamage))damage=1;
					armourdamage=random(0,originaldamage>>2);
				}
				else damage=0;
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
			"bashing",DMG_NO_ARMOR|DMG_THRUSTLESS
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

		double addpenshell=35;

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
			double bad=min(pen,addpenshell)*bullet.stamina*0.0005;
			armourdamage=random(-1,int(bad));

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

	states{
	spawn:
		TNT1 A 0;
		stop;
	}
}

class CorporateArmour : HDPickupGiver {
	default {
		//$Category "Items/Hideous Destructor"
		//$Title "Corporate Armour"
		//$Sprite "CARMA0"
		+hdpickup.fitsinbackpack
		+inventory.isarmor
		inventory.icon "CARMA0";
		hdpickupgiver.pickuptogive "HDCorporateArmour";
		hdpickup.bulk ENC_CORPORATEARMOUR;
		hdpickup.refid "aru";
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

class CorporateArmourWorn : HDPickup{
	default {
		-hdpickup.fitsinbackpack
		+inventory.isarmor
		hdpickup.refid "awu";
		tag "corporate armour";
		inventory.maxamount 1;
	}

	override void postbeginplay() {
		super.postbeginplay();
		if(owner) {
			for(inventory iii=owner.inv;iii!=null;iii=iii.inv){
				let hdp=hdpickup(iii);
				if(hdp&&hdp.wornlayer==STRIP_ARMOUR)hdp.destroy();
			}
			owner.A_GiveInventory("HDCorporateArmourWorn");
		}
		destroy();
	}
}
