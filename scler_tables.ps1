# scler_tables.ps1 - reference tables for SCLER
# Loaded by scler.ps1

# Rank key table: global.ini key -> English rank name
$rankKeyTable = @{
    'RepScope_Contractor_Rank0'              = 'Applicant'
    'RepScope_Contractor_Rank1'              = 'Jr. Contractor'
    'RepScope_Contractor_Rank2'              = 'Contractor'
    'RepScope_Contractor_Rank3'              = 'Sr. Contractor'
    'RepScope_Contractor_Rank4'              = 'Veteran Contractor'
    'RepScope_Contractor_Rank5'              = 'Head Contractor'
    'RepScope_Contractor_Rank6'              = 'Elite Contractor'
    'RepScope_HiredMuscle_Rank0'             = 'Under Review'
    'RepScope_HiredMuscle_Rank1'             = 'Foot Soldier'
    'RepScope_HiredMuscle_Rank2'             = 'Low Level Enforcer'
    'RepScope_HiredMuscle_Rank3'             = 'Enforcer'
    'RepScope_HiredMuscle_Rank4'             = 'Experienced Enforcer'
    'RepScope_HiredMuscle_Rank5'             = 'Trusted Enforcer'
    'RepScope_HiredMuscle_Rank6'             = 'Lethal Enforcer'
    'RepScope_Maintenance_Rank0'             = 'Apprentice'
    'RepScope_Maintenance_Rank1'             = 'Mechanic-in-Training'
    'RepScope_Maintenance_Rank2'             = 'Jr. Mechanic'
    'RepScope_Maintenance_Rank3'             = 'Mechanic'
    'RepScope_Maintenance_Rank4'             = 'Sr. Mechanic'
    'RepScope_Maintenance_Rank5'             = 'Master Mechanic'
    'RepScope_Technician_Rank0'              = 'Applicant'
    'RepScope_Technician_Rank1'              = 'Technician-in-Training'
    'RepScope_Technician_Rank2'              = 'Jr. Technician'
    'RepScope_Technician_Rank3'              = 'Technician'
    'RepScope_Technician_Rank4'              = 'Sr. Technician'
    'RepScope_Technician_Rank5'              = 'Master Technician'
    'RepStanding_Assassination_Rank0'        = 'Under Review'
    'RepStanding_Assassination_Rank1'        = 'Assassin In Training'
    'RepStanding_Assassination_Rank2'        = 'Low Level Assassin'
    'RepStanding_Assassination_Rank3'        = 'Assassin'
    'RepStanding_Assassination_Rank4'        = 'High Value Assassin'
    'RepStanding_Assassination_Rank5'        = 'Elite Assassin'
    'RepStanding_Assassination_Rank6'        = 'Master Assassin'
    'RepStanding_Barter_Rank0_Name'          = 'New Customer'
    'RepStanding_Barter_Rank1_Name'          = 'Very Good Customer'
    'RepStanding_Barter_Rank1_Perk'          = 'Special Wolf Barter Contract'
    'RepStanding_Barter_Rank2_Name'          = 'Very Best Customer'
    'RepStanding_Barter_Rank2_Perk'          = 'Special Idris-P Barter Contract'
    'RepStanding_Bounty_Rank0'               = 'Applicant'
    'RepStanding_Bounty_Rank1'               = 'Tracker Trainee'
    'RepStanding_Bounty_Rank2'               = 'Associate Tracker'
    'RepStanding_Bounty_Rank3'               = 'Tracker'
    'RepStanding_Bounty_Rank4'               = 'Advanced Tracker'
    'RepStanding_Bounty_Rank5'               = 'Senior Tracker'
    'RepStanding_Bounty_Rank6'               = 'Master Tracker'
    'RepStanding_Courier_Rank0'              = 'Applicant'
    'RepStanding_Courier_Rank1'              = 'Jr. Runner'
    'RepStanding_Courier_Rank2'              = 'Runner'
    'RepStanding_Courier_Rank3'              = 'Sr. Runner'
    'RepStanding_Emergency_Rank0'            = 'Applicant'
    'RepStanding_Emergency_Rank1'            = 'First Responder Trainee'
    'RepStanding_Emergency_Rank2'            = 'First Responder'
    'RepStanding_Emergency_Rank3'            = 'Veteran First Responder'
    'RepStanding_Livery_Rank0'               = 'Probationary Livery Pilot'
    'RepStanding_Livery_Rank1'               = 'Jr. Livery Pilot'
    'RepStanding_Livery_Rank2'               = 'Livery Pilot'
    'RepStanding_Livery_Rank3'               = 'Sr. Livery Pilot'
    'RepStanding_Rank0'                      = 'Applicant'
    'RepStanding_Rank1'                      = 'Rank I'
    'RepStanding_Rank10'                     = 'Rank X'
    'RepStanding_Rank2'                      = 'Rank II'
    'RepStanding_Rank3'                      = 'Rank III'
    'RepStanding_Rank4'                      = 'Rank IV'
    'RepStanding_Rank5'                      = 'Rank V'
    'RepStanding_Rank6'                      = 'Rank VI'
    'RepStanding_Rank7'                      = 'Rank VII'
    'RepStanding_Rank8'                      = 'Rank VIII'
    'RepStanding_Rank9'                      = 'Rank IX'
    'RepStanding_Salvaging_Rank0'            = 'Applicant'
    'RepStanding_Salvaging_Rank1'            = 'Apprentice Salvager'
    'RepStanding_Salvaging_Rank2'            = 'Associate Salvager'
    'RepStanding_Salvaging_Rank3'            = 'Salvager'
    'RepStanding_Salvaging_Rank4'            = 'Senior Salvager'
    'RepStanding_Salvaging_Rank5'            = 'Master Salvager'
    'RepStanding_Scavenging_Rank0'           = 'Prospective Scavenger'
    'RepStanding_Scavenging_Rank1'           = 'Rust Collector'
    'RepStanding_Scavenging_Rank2'           = 'Scavenger'
    'RepStanding_Scavenging_Rank3'           = 'Enterprising Scavenger'
    'RepStanding_Scavenging_Rank4'           = 'Trusted Scavenger'
    'RepStanding_Scavenging_Rank5'           = 'Expert Scavenger'
    'RepStanding_Security_Rank0'             = 'Applicant'
    'RepStanding_Security_Rank1'             = 'Security Trainee'
    'RepStanding_Security_Rank2'             = 'Jr. Security Contractor'
    'RepStanding_Security_Rank3'             = 'Security Contractor'
    'RepStanding_Security_Rank4'             = 'Sr. Security Contractor'
    'RepStanding_Security_Rank5'             = 'Lead Security Contractor'
    'RepStanding_Security_Rank6'             = 'Elite Security Contractor'
    'RepStanding_TransportGuild_Rank0'       = 'Trainee'
    'RepStanding_TransportGuild_Rank1'       = 'Rookie'
    'RepStanding_TransportGuild_Rank2'       = 'Junior'
    'RepStanding_TransportGuild_Rank3'       = 'Member'
    'RepStanding_TransportGuild_Rank4'       = 'Experienced'
    'RepStanding_TransportGuild_Rank5'       = 'Senior'
    'RepStanding_TransportGuild_Rank6'       = 'Master'
    'Neutral'                                = 'Neutral'
}

# Item type key table: global.ini key -> English type name(s)
$itemTypeKeyTable = @{
    'item_Name_COMP_Default' = @('Computer')
    'item_Name_COOL_Default' = @('Cooler')
    'item_Name_HTNK_Default' = @('Hydrogen Fuel Tank')
    'item_Name_INTK_Default' = @('Fuel Intake')
    'item_Name_POWR_Default' = @('Power Plant', 'Powerplant')
    'item_Name_QDRV_Default' = @('Quantum Drive')
    'item_Name_QTNK_Default' = @('Quantum Fuel Tank')
    'item_Name_RADR_Default' = @('Radar')
    'item_Name_SHLD_Default' = @('Shield Generator', 'Shield')
}

# Additional translations
$additionalItemTypes = @{
    'Salvage Mod'  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JDQsdGA0LDQty4g0L/RgNC40YHQvy4='))
    'Fuel Nozzle'  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KLQvtC/0LsuINGE0L7RgNGB0YPQvdC60LA='))
    'cap'          = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0L/QsNGC0YAu'))
    'Mining Laser' = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JTQvtCxLiDQu9Cw0LfQtdGA'))
}

# Russian localization texts (Base64-encoded)
$locPotential        = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JTQvtGB0YLRg9C/0L3Ri9C1INGH0LXRgNGC0LXQttC4'))
$locBP               = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KfQtdGA0YLQtdC20Lg='))
$extraFrontend       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KDQsNGB0YjQuNGA0LXQvdC90LDRjyDQuNC90YTQvtGA0LzQsNGG0LjRjyDQviDQvdCw0LPRgNCw0LTQsNGFINCyINC30LDQtNCw0L3QuNGP0YU='))
$locOnly             = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0YLQvtC70YzQutC+'))
$locRepeatOnly       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0YLQvtC70YzQutC+INC/0L7QstGC0L7RgA=='))
$locMbp              = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JzQvdC+0LbQtdGB0YLQstC10L3QvdGL0LUg0L/Rg9C70Ysg0YfQtdGA0YLQtdC20LXQuQ=='))
$locPool             = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0J/Rg9C7'))
$locAwardedFrom      = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0J3QsNCz0YDQsNC00LAg0LjQtyDQstCw0YDQuNCw0L3RgtC+0LIg0YPRgNC+0LLQvdGP'))
$locRpBasic          = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KDQtdC/0YPRgtCw0YbQuNGPINC30LAg0LLRi9C/0L7Qu9C90LXQvdC40LU6'))
$locRpDiff           = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KDQtdC/0YPRgtCw0YbQuNGPINC30LAg0LLRi9C/0L7Qu9C90LXQvdC40LUgKNC+0YIg0YHQu9C+0LbQvdC+0YHRgtC4KTo='))
$locSpp              = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0J7Rh9C60Lgg0L/RgNC+0LPRgNC10YHRgdCwINGB0YbQtdC90LDRgNC40Y86'))
$locRegionalVariants = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('W9Cg0LXQs9C40L7QvdCw0LvRjNC90YvQtSDQstCw0YDQuNCw0L3RgtGLXSDQv9GA0LjQvNC10YDRiyDQu9C+0LrQsNGG0LjQuTo='))
$locNotesMarker      = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JfQsNC80LXRgtC60Lg6'))
$locModifiedByPlayer = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0LzQvtC00LjRhNC40YbQuNGA0L7QstCw0L3QviDQuNCz0YDQvtC60L7QvA=='))
$locCargoHaul        = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0J/QldCg0JXQktCe0JfQmtCQ'))
$locCargoFrom        = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JjQlw=='))
$locCargoTo          = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JI='))
$locCargoChain       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0KbQldCf0J7Qp9Ca0JAg0J/QldCg0JXQktCe0JfQntCa'))
$locCargoRound       = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JrQoNCj0JPQntCS0JDQryDQn9CV0KDQldCS0J7Ql9Ca0JA='))