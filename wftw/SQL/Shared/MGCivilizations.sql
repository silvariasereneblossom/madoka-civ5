-- [port] Which civilizations take part in the Magical Girl system.
-- With the define MAGICAL_GIRLS_EXCLUSIVE_TO_MG_CIVS at 1 (the default), only leaders whose trait has
-- HasMagicalGirls = 1 get a Leader Magical Girl, turn expended Great People into Magical Girls, receive
-- Hidden Witch Barriers or see the Grief Seed counter. Witches still replace Barbarians for everyone.
-- Other civilization packs opt in by setting the column on their own trait. Set the define to 0 to
-- restore the original behaviour where every civilization and city-state has Magical Girls.
UPDATE Traits SET HasMagicalGirls = 1 WHERE Type IN (
	'TRAIT_FREE_ARCHERY_BONUS_GARRISON_ATTACK',
	'TRAIT_NO_WITCHES',
	'TRAIT_STEAL_ENEMY_UNIQUE_ON_CONQUEST',
	'TRAIT_NO_GREAT_PEOPLE_CAPITAL_YIELD_FROM_MG_KILLS',
	'TRAIT_TOURISM_HEALING_BONUS',
	'TRAIT_GROWTH_SPEED_FROM_RELIGION',
	'TRAIT_FRIENDSHIP_PRODUCTION_BONUS',
	'TRAIT_CATTLE_BONUS_MERCHANT_PLANT_CATTLE',
	'TRAIT_MG_FROM_WITCHES_STORE_KILLED_MGS',
	'TRAIT_FREE_SPIES_IMMUNE_TO_TRUTH'
);
