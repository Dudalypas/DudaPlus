Config = Config or {}

-- Global rarity metadata used by the wear system, payouts, and upgrades.
Config.RarityMultipliers = Config.RarityMultipliers or {
    [1] = 1.0,
    [2] = 1.50,
    [3] = 2.00,
    [4] = 2.70,
    [5] = 3.50,
}

Config.RarityUpgrade = Config.RarityUpgrade or {}
Config.RarityUpgrade.account = Config.RarityUpgrade.account or 'bank'
Config.RarityUpgrade.costs = Config.RarityUpgrade.costs or {
    [1] = { next = 2, cost = 40000 },
    [2] = { next = 3, cost = 100000 },
    [3] = { next = 4, cost = 220000 },
    [4] = { next = 5, cost = 900000 },
}
Config.RarityUpgrade.maxRarity = Config.RarityUpgrade.maxRarity or 5
Config.RarityUpgrade.warningR5 = Config.RarityUpgrade.warningR5
    or "This upgrade costs more than some legendary vehicles and is intended only for owners committed to this specific car."

-- Vehicle condition rarity tiers influence mileage / wear rolls.
Config.Rarity = {
    [1] = { label = "Common",    hi = 300000, full = 520000, maxDamages = 3, mileageMin = 60000, mileageMax = 520000, skewToHigh = true,  skewPow = 1.3 },
    [2] = { label = "Uncommon",  hi = 220000, full = 420000, maxDamages = 3, mileageMin = 30000, mileageMax = 420000, skewToHigh = true,  skewPow = 1.4 },
    [3] = { label = "Rare",      hi = 160000, full = 320000, maxDamages = 4, mileageMin = 15000, mileageMax = 320000, skewToHigh = false, skewPow = 1.3 },
    [4] = { label = "Epic",      hi = 110000, full = 230000, maxDamages = 4, mileageMin = 5000,  mileageMax = 230000, skewToHigh = false, skewPow = 1.8 },
    [5] = { label = "Legendary", hi =  70000, full = 150000, maxDamages = 5, mileageMin = 0,     mileageMax = 150000, skewToHigh = false, skewPow = 2.0 },
}

Config.ConditionLabels = {
    { threshold = 0.20, label = "New" },
    { threshold = 0.40, label = "Minimal wear" },
    { threshold = 0.65, label = "Field-tested" },
    { threshold = 0.85, label = "Heavy wear" },
    { threshold = 1.01, label = "Critical" },
}

-- Damage definitions are shared by server/client so effects stay consistent.
Config.DamageTypes = {

    broken_turbo = {
        label = "Burned turbocharger (reduced power)",
        minWear = 0.45,
        baseChance = 0.10,
        chanceAtFullWear = 0.42,
        sevMin = 0.45,
        sevMax = 0.98,
        effects = {
            { kind = "float", type = "mul", field = "fInitialDriveForce",      value = 0.69 },
            { kind = "float", type = "mul", field = "fDriveInertia",           value = 0.78 },
            { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.85 },
        }
    },

    worn_tires = {
        label = "Worn tires, unstable front axle",
        minWear = 0.25,
        baseChance = 0.18,
        chanceAtFullWear = 0.50,
        sevMin = 0.40,
        sevMax = 0.92,
        effects = {
            { kind = "float", type = "mul", field = "fTractionCurveMax",         value = 0.80 },
            { kind = "float", type = "mul", field = "fTractionCurveMin",         value = 0.82 },
            { kind = "float", type = "mul", field = "fTractionCurveLateral",     value = 0.90 },
            { kind = "float", type = "add", field = "fLowSpeedTractionLossMult", value = 0.28 },
            { kind = "float", type = "mul", field = "fTractionLossMult",         value = 1.12 },
        }
    },

    bent_suspension = {
        label = "Bent suspension, uneven tire wear",
        minWear = 0.40,
        baseChance = 0.12,
        chanceAtFullWear = 0.40,
        sevMin = 0.40,
        sevMax = 0.92,
        effects = {
            { kind = "float", type = "mul", field = "fSteeringLock",          value = 0.86 },
            { kind = "float", type = "mul", field = "fTractionCurveLateral",  value = 0.88 },
            { kind = "float", type = "mul", field = "fSuspensionReboundDamp", value = 0.78 },
            { kind = "float", type = "mul", field = "fSuspensionCompDamp",    value = 0.82 },
        }
    },

    warped_rotors = {
        label = "Worn brake rotors (vibration when braking)",
        minWear = 0.35,
        baseChance = 0.14,
        chanceAtFullWear = 0.45,
        sevMin = 0.35,
        sevMax = 0.90,
        effects = {
            { kind = "float", type = "mul", field = "fBrakeForce",     value = 0.65 },
            { kind = "float", type = "mul", field = "fBrakeBiasFront", value = 0.92 },
            { kind = "float", type = "mul", field = "fHandBrakeForce", value = 0.90 },
        }
    },

    bad_alignment = {
        label = "Unaligned wheels (unstable front axle)",
        minWear = 0.20,
        baseChance = 0.20,
        chanceAtFullWear = 0.48,
        sevMin = 0.35,
        sevMax = 0.90,
        effects = {
            { kind = "float", type = "mul", field = "fTractionBiasFront", value = 0.88 },
            { kind = "float", type = "mul", field = "fTractionLossMult",  value = 1.16 },
            { kind = "float", type = "mul", field = "fSteeringLock",      value = 0.92 },
        }
    },

    engine_misfire = {
        label = "Engine misfire (ignition problems)",
        minWear = 0.30,
        baseChance = 0.12,
        chanceAtFullWear = 0.40,
        sevMin = 0.40,
        sevMax = 0.98,
        effects = {
            { kind = "float", type = "mul", field = "fInitialDriveForce",      value = 0.70 },
            { kind = "float", type = "mul", field = "fDriveInertia",           value = 0.78 },
            { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.90 },
        }
    },

    clutch_slip = {
        label = "Clutch slip (power not transmitted)",
        minWear = 0.35,
        baseChance = 0.12,
        chanceAtFullWear = 0.42,
        sevMin = 0.45,
        sevMax = 0.98,
        effects = {
            { kind = "float", type = "mul", field = "fClutchChangeRateScaleUpShift",   value = 0.62 },
            { kind = "float", type = "mul", field = "fClutchChangeRateScaleDownShift", value = 0.72 },
            { kind = "float", type = "mul", field = "fDriveInertia",                   value = 0.88 },
        }
    },

    worn_diff = {
        label = "Worn differential (loses traction)",
        minWear = 0.40,
        baseChance = 0.10,
        chanceAtFullWear = 0.36,
        sevMin = 0.40,
        sevMax = 0.92,
        effects = {
            { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.86 },
            { kind = "float", type = "mul", field = "fTractionLossMult",     value = 1.18 },
            { kind = "float", type = "mul", field = "fTractionCurveMax",     value = 0.92 },
        }
    },

    leaking_shocks = {
        label = "Leaking shocks (reduced suspension performance)",
        minWear = 0.25,
        baseChance = 0.16,
        chanceAtFullWear = 0.48,
        sevMin = 0.40,
        sevMax = 0.95,
        effects = {
            { kind = "float", type = "mul", field = "fSuspensionCompDamp",    value = 0.74 },
            { kind = "float", type = "mul", field = "fSuspensionReboundDamp", value = 0.70 },
            { kind = "float", type = "mul", field = "fSuspensionForce",       value = 0.90 },
        }
    },

    weak_brake_lines = {
        label = "Worn brake lines (air / fluid problems)",
        minWear = 0.45,
        baseChance = 0.10,
        chanceAtFullWear = 0.34,
        sevMin = 0.45,
        sevMax = 0.98,
        effects = {
            { kind = "float", type = "mul", field = "fBrakeForce",     value = 0.58 },
            { kind = "float", type = "mul", field = "fBrakeBiasFront", value = 0.90 },
            { kind = "float", type = "mul", field = "fHandBrakeForce", value = 0.85 },
        }
    },

    transmission_wear = {
        label = "Worn transmission (slipping gears)",
        minWear = 0.50,
        baseChance = 0.10,
        chanceAtFullWear = 0.32,
        sevMin = 0.50,
        sevMax = 0.98,
        effects = {
            { kind = "float", type = "mul", field = "fDriveInertia",           value = 0.76 },
            { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.82 },
            { kind = "float", type = "mul", field = "fClutchChangeRateScaleUpShift",   value = 0.85 },
            { kind = "float", type = "mul", field = "fClutchChangeRateScaleDownShift", value = 0.88 },
        }
    },

    turbo_lag = {
        label = "Burned turbocharger (reduced power)",
        minWear = 0.20,
        baseChance = 0.14,
        chanceAtFullWear = 0.46,
        sevMin = 0.35,
        sevMax = 0.90,
        effects = {
            { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.82 },
            { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.92 },
        }
    },

    frame_fatigue = {
        label = "Worn frame (unstable handling)",
        minWear = 0.55,
        baseChance = 0.08,
        chanceAtFullWear = 0.28,
        sevMin = 0.40,
        sevMax = 0.88,
        effects = {
            { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.86 },
            { kind = "float", type = "mul", field = "fSteeringLock",         value = 0.88 },
            { kind = "float", type = "mul", field = "fAntiRollBarForce",     value = 0.86 },
        }
    },
    overheating_engine = {
        label = "Overheating engine (power limitation)",
        minWear = 0.35,
        baseChance = 0.10,
        chanceAtFullWear = 0.38,
        sevMin = 0.40,
        sevMax = 0.95,
        effects = {
            { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.78 },
            { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.85 },
        }
    },

    worn_engine_mounts = {
        label = "Worn engine mounts (reduced power)",
        minWear = 0.30,
        baseChance = 0.12,
        chanceAtFullWear = 0.40,
        sevMin = 0.35,
        sevMax = 0.90,
        effects = {
            { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.88 },
            { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.94 },
        }
    },

    worn_steering_rack = {
        label = "Worn steering rack (unstable handling)",
        minWear = 0.25,
        baseChance = 0.16,
        chanceAtFullWear = 0.48,
        sevMin = 0.40,
        sevMax = 0.92,
        effects = {
            { kind = "float", type = "mul", field = "fSteeringLock", value = 0.90 },
            { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.92 },
        }
    },

    worn_driveshaft = {
        label = "Worn driveshaf",
        minWear = 0.40,
        baseChance = 0.10,
        chanceAtFullWear = 0.36,
        sevMin = 0.40,
        sevMax = 0.90,
        effects = {
            { kind = "float", type = "mul", field = "fDriveInertia", value = 0.84 },
            { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.88 },
        }
    },
    blown_head_gasket = {
    label = "Blown head gasket",
    minWear = 0.65,
    baseChance = 0.05,
    chanceAtFullWear = 0.22,
    sevMin = 0.55,
    sevMax = 1.00,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.62 },
        { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.70 },
        { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.78 },
    }
},
oil_starvation = {
    label = "Engine oil starvation (severe engine damage)",
    minWear = 0.65,
    baseChance = 0.05,
    chanceAtFullWear = 0.20,
    sevMin = 0.60,
    sevMax = 1.00,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.60 },
        { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.68 },
    }
},

oil_starvation = {
    label = "Dead engine",
    minWear = 0.65,
    baseChance = 0.05,
    chanceAtFullWear = 0.20,
    sevMin = 0.60,
    sevMax = 1.00,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.60 },
        { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.68 },
    }
},
thermal_saturation = {
    label = "Overheated engine (severe power loss)",
    minWear = 0.50,
    baseChance = 0.08,
    chanceAtFullWear = 0.30,
    sevMin = 0.50,
    sevMax = 0.95,
    effects = {
        { kind = "float", type = "mul", field = "fTractionCurveMax",     value = 0.82 },
        { kind = "float", type = "mul", field = "fTractionCurveMin",     value = 0.85 },
        { kind = "float", type = "mul", field = "fBrakeForce",           value = 0.78 },
    }
},
cracked_exhaust_manifold = {
    label = "Cracked exhaust manifold",
    minWear = 0.30,
    baseChance = 0.14,
    chanceAtFullWear = 0.42,
    sevMin = 0.40,
    sevMax = 0.90,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.88 },
        { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.90 },
    }
},
fuel_pressure_regulator = {
    label = "Worn fuel pressure regulator",
    minWear = 0.35,
    baseChance = 0.12,
    chanceAtFullWear = 0.38,
    sevMin = 0.45,
    sevMax = 0.95,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.75 },
        { kind = "float", type = "mul", field = "fDriveInertia",      value = 0.85 },
    }
},
vvt_actuator_wear = {
    label = "Worn VVT actuator",
    minWear = 0.40,
    baseChance = 0.10,
    chanceAtFullWear = 0.34,
    sevMin = 0.40,
    sevMax = 0.90,
    effects = {
        { kind = "float", type = "mul", field = "fInitialDriveForce", value = 0.82 },
        { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.90 },
    }
},
steering_column_joints = {
    label = "Worn steering column joints",
    minWear = 0.25,
    baseChance = 0.16,
    chanceAtFullWear = 0.48,
    sevMin = 0.40,
    sevMax = 0.92,
    effects = {
        { kind = "float", type = "mul", field = "fSteeringLock", value = 0.88 },
        { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.94 },
    }
},
wheel_bearing_failure = {
    label = "Worn wheel bearings",
    minWear = 0.35,
    baseChance = 0.14,
    chanceAtFullWear = 0.46,
    sevMin = 0.40,
    sevMax = 0.95,
    effects = {
        { kind = "float", type = "mul", field = "fTractionCurveLateral", value = 0.90 },
        { kind = "float", type = "mul", field = "fInitialDriveMaxFlatVel", value = 0.92 },
    }
}

}


-- Whitelist of handling fields we allow to store/replicate, plus sanity limits.
Config.ConditionHandling = {
    floats = {
        fMass = { min = 10.0, max = 10000.0 },
        fInitialDragCoeff = { min = 0.0, max = 90.0 },
        fPercentSubmerged = { min = 0.0, max = 120.0 },
        fDriveBiasFront = { min = 0.0, max = 1.0 },
        fInitialDriveForce = { min = 0.01, max = 5.0 },
        fDriveInertia = { min = 0.01, max = 10.0 },
        fClutchChangeRateScaleUpShift = { min = 0.1, max = 10.0 },
        fClutchChangeRateScaleDownShift = { min = 0.1, max = 10.0 },
        fInitialDriveMaxFlatVel = { min = 1.0, max = 500.0 },
        fBrakeForce = { min = 0.01, max = 10.0 },
        fBrakeBiasFront = { min = 0.0, max = 1.0 },
        fHandBrakeForce = { min = 0.0, max = 10.0 },
        fSteeringLock = { min = 1.0, max = 150.0 },
        fTractionCurveMax = { min = 0.1, max = 10.0 },
        fTractionCurveMin = { min = 0.1, max = 10.0 },
        fTractionCurveLateral = { min = 0.1, max = 10.0 },
        fTractionSpringDeltaMax = { min = 0.0, max = 10.0 },
        fLowSpeedTractionLossMult = { min = 0.0, max = 10.0 },
        fCamberStiffnesss = { min = -5.0, max = 5.0 },
        fTractionBiasFront = { min = 0.0, max = 1.0 },
        fTractionLossMult = { min = 0.0, max = 10.0 },
        fSuspensionForce = { min = 0.0, max = 20.0 },
        fSuspensionCompDamp = { min = 0.0, max = 20.0 },
        fSuspensionReboundDamp = { min = 0.0, max = 20.0 },
        fSuspensionUpperLimit = { min = -1.0, max = 1.0 },
        fSuspensionLowerLimit = { min = -1.0, max = 1.0 },
        fSuspensionRaise = { min = -1.0, max = 1.0 },
        fSuspensionBiasFront = { min = 0.0, max = 1.0 },
        fAntiRollBarForce = { min = 0.0, max = 20.0 },
        fAntiRollBarBiasFront = { min = 0.0, max = 1.0 },
        fRollCentreHeightFront = { min = -2.0, max = 2.0 },
        fRollCentreHeightRear = { min = -2.0, max = 2.0 },
        fCollisionDamageMult = { min = 0.0, max = 10.0 },
        fWeaponDamageMult = { min = 0.0, max = 10.0 },
        fDeformationDamageMult = { min = 0.0, max = 10.0 },
        fEngineDamageMult = { min = 0.0, max = 10.0 },
        fPetrolTankVolume = { min = 0.0, max = 120.0 },
        fOilVolume = { min = 0.0, max = 30.0 },
        fPetrolConsumptionRate = { min = 0.0, max = 10.0 },
        fSeatOffsetDistX = { min = -1.0, max = 1.0 },
        fSeatOffsetDistY = { min = -1.0, max = 1.0 },
        fSeatOffsetDistZ = { min = -1.0, max = 1.0 },
    },
    ints = {
        nInitialDriveGears = { min = 1, max = 10 },
        nMonetaryValue = { min = 0, max = 10000000 }
    },
    vectors = {
        vecCentreOfMassOffset = {
            x = { min = -5.0, max = 5.0 },
            y = { min = -5.0, max = 5.0 },
            z = { min = -5.0, max = 5.0 },
        },
        vecInertiaMultiplier = {
            x = { min = 0.01, max = 10.0 },
            y = { min = 0.01, max = 10.0 },
            z = { min = 0.01, max = 10.0 },
        }
    }
}
