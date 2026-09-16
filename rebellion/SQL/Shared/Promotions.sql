--**********************************************************************************************
--Promotions for Unique Units (Magical Girl promotions in a separate file)
--**********************************************************************************************

--Define all promotions identically, then later in the file, add their effects.

INSERT INTO UnitPromotions
			(Type,											Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_INCUBATOR_SLAVE'),					('TXT_KEY_PROMOTION_INCUBATOR_SLAVE'),		('TXT_KEY_PROMOTION_INCUBATOR_SLAVE_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_INCUBATOR_SLAVE')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,											Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_WITCH'),					('TXT_KEY_PROMOTION_PMMM_WITCH'),		('TXT_KEY_PROMOTION_PMMM_WITCH_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_WITCH')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_UNWELCOME_EVANGELIST');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_CLOCKSTOPPER'),			('TXT_KEY_PROMOTION_PMMM_CLOCKSTOPPER'),	('TXT_KEY_PROMOTION_PMMM_CLOCKSTOPPER_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_CLOCKSTOPPER')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_CHAIN_LANCER'),			('TXT_KEY_PROMOTION_PMMM_CHAIN_LANCER'),	('TXT_KEY_PROMOTION_PMMM_CHAIN_LANCER_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_CHAIN_LANCER')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_ROSEBOW_INFANTRY'),		('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY'),('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS'),		('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS'),('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS_IMPROVEMENT'),		('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS'),('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_ROSEBOW_INFANTRY')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_TIRO_MUSKETEER'),			('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER'),	('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_BUBBLE_BOMBER'),			('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER'),	('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_BUBBLE_BOMBER_BONUS'),			('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER_BONUS'),	('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER_BONUS_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_BUBBLE_BOMBER')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_TIME_STOP'),		('TXT_KEY_PROMOTION_PMMM_TIME_STOP'),('TXT_KEY_PROMOTION_PMMM_TIME_STOP_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_TIME_STOP')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_UNWELCOME_EVANGELIST');

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_PMMM_TIRO_MUSKETEER_BONUS'),		('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER_BONUS'),('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER_BONUS_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_PMMM_TIRO_MUSKETEER_BONUS')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');

INSERT INTO UnitPromotions	
			(Type,										Description,								Help,						
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	PediaEntry)
SELECT		('PROMOTION_NEW_HOMURA_TRAIT'),		('TXT_KEY_PROMOTION_NEW_HOMURA_TRAIT'),('TXT_KEY_PROMOTION_NEW_HOMURA_TRAIT_HELP'),
			CannotBeChosen,		Sound,	PortraitIndex,	IconAtlas,	PediaType,	('TXT_KEY_PROMOTION_NEW_HOMURA_TRAIT')
FROM UnitPromotions	WHERE (Type = 'PROMOTION_STEAM_POWERED');


/* -----------------------------------------------------
						Thief of Time
   --------------------------------------------------- */

UPDATE UnitPromotions
SET ObtainUniqueUnitPromotionOnCityCapture=1
WHERE Type = 'PROMOTION_PMMM_CLOCKSTOPPER';

/* -----------------------------------------------------
						Chain Lancer
   --------------------------------------------------- */

UPDATE UnitPromotions
SET FlankAttackModifier=100
WHERE Type = 'PROMOTION_PMMM_CHAIN_LANCER';

/* -----------------------------------------------------
						Rosebow Infantry
   --------------------------------------------------- */

INSERT INTO Promotion_PMMM_GrantNewPromotionOnImprovement
			(PromotionType,ImprovementType,NewPromotionType)
VALUES		('PROMOTION_PMMM_ROSEBOW_INFANTRY','IMPROVEMENT_CITADEL','PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS_IMPROVEMENT');

UPDATE UnitPromotions
SET NewPromotionInCity='PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS'
WHERE Type = 'PROMOTION_PMMM_ROSEBOW_INFANTRY';

UPDATE UnitPromotions
SET ExtraAttacks=1,CanMoveAfterAttacking=1
WHERE Type = 'PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS';

UPDATE UnitPromotions
SET ExtraAttacks=1,CanMoveAfterAttacking=1
WHERE Type = 'PROMOTION_PMMM_ROSEBOW_INFANTRY_BONUS_IMPROVEMENT';


/* -----------------------------------------------------
						Tiro Musketeer
   --------------------------------------------------- */

UPDATE UnitPromotions
SET RangedSupportFire=1
WHERE Type = 'PROMOTION_PMMM_TIRO_MUSKETEER';

UPDATE UnitPromotions
SET CombatPercent = 25
WHERE Type = 'PROMOTION_PMMM_TIRO_MUSKETEER_BONUS';

/* -----------------------------------------------------
						Bubble Bomber
   --------------------------------------------------- */

UPDATE UnitPromotions
SET CityAttack=50, AttackFortifiedMod=50
WHERE Type = 'PROMOTION_PMMM_BUBBLE_BOMBER';

UPDATE UnitPromotions
SET RangedAttackModifier=33
WHERE Type = 'PROMOTION_PMMM_BUBBLE_BOMBER_BONUS';

INSERT INTO Promotion_PMMM_GrantNewPromotionNearEnemy
			(PromotionType,Radius,NewPromotionType)
VALUES		('PROMOTION_PMMM_BUBBLE_BOMBER',2,'PROMOTION_PMMM_BUBBLE_BOMBER_BONUS');



/* -----------------------------------------------------
						Witch
   --------------------------------------------------- */

UPDATE UnitPromotions
SET OutsideFriendlyLandsModifier = -50, LostWithUpgrade = 1
WHERE Type = 'PROMOTION_PMMM_WITCH';



/* -----------------------------------------------------
					Homura v12 Trait
   --------------------------------------------------- */

UPDATE UnitPromotions
SET ExtraWithdrawal = 80, RangedDefenseMod = 33
WHERE Type = 'PROMOTION_NEW_HOMURA_TRAIT';