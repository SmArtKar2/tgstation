//Relation defines//
#define SHIP_ALLIED_RELATIONSHIP 50
#define SHIP_HOSTILE_RELATIONSHIP -25
#define SHIP_MAX_RELATIONSHIP 100
#define SHIP_MIN_RELATIONSHIP 0


//Ship components//
#define SHIP_CONTROL 1
#define SHIP_WEAPONS 2
#define SHIP_SHIELDS 4
#define SHIP_REPAIR 8
#define SHIP_ENGINES 16
#define SHIP_OPEN 32

#define MIN_SHIELD_STRENGTH 500 //Minimum shield strength for shield to protect from damage

//Event types//
#define SHIP_COMBAT 1
#define SHIP_CHOICE 2
#define SHIP_QUEST 4
#define SHIP_PASSIVE 8
#define SHIP_RUIN 16

//Event rarity//
#define SHIP_COMMON_EVENT 100
#define SHIP_UNCOMMON_EVENT 50
#define SHIP_RARE_EVENT 25
#define SHIP_EPIC_EVENT 5
#define SHIP_LEGENDARY_EVENT 1

//Factions//
#define SHIP_PLAYERSHIP "station" //Player's ship, doesn't own any systems
#define SHIP_NANOTRASEN "nanotrasen"
#define SHIP_SYNDICATE "syndicate"
#define SHIP_SOLGOV "solgov"
#define SHIP_PIRATE "pirate" //doesn't own any systems
#define SHIP_NEUTRAL "unaligned" //These are used for things that fit within any group
