/* ==========================================================================
   Angular Contact Slewing Bearing for "Ballie Mk. I"
   Approach A: Hybrid Geometry Fix (Chamfered Tolerances)
   FLAT PRINT LAYOUT (Designed for 256x256mm Build Plate)
   ========================================================================== */

$fn = 120; // High resolution for smooth kinematics

// ==========================================================================
// 1. TUNING & TOLERANCE VARIABLES
// ==========================================================================
ring_gap = 0.5;          // INCREASED: 0.5mm baseline gap 
relief_chamfer = 1.2;    // NEW: Chamfer at extreme edges to handle bending moments
axle_clearance = 0.45;   // More slack to reduce spike friction
roller_slop = 0.15;      // Clearance for the V-groove
roller_bore_dia = 2.5;   // Diameter of the hollow core (and base for the axle)

// ==========================================================================
// 2. STRUCTURAL DIMENSIONS
// ==========================================================================
bearing_od = 120;        // Outer diameter
bearing_id = 70;         // Inner diameter
bearing_height = 12;     // Total Z-axis height
race_radius = 47.5;      // Perfectly centered between ID and OD to clear screws

// ==========================================================================
// 3. ROLLER DIMENSIONS
// ==========================================================================
roller_dia = 6.5;        // Outer diameter of the cylindrical roller
roller_length = 6.5;     // Length of the roller
roller_count = 12;       // Kept at 12 for lower friction

// ==========================================================================
// 4. HARDWARE & MOUNTING VARIABLES
// ==========================================================================
inner_hole_radius = 40.6; // Matches HemisphereRotor exactly
outer_hole_radius = 54.5; 
hole_count = 8;           

hole_dia_m3_clear = 3.4;  
countersink_dia = 6.5;    
countersink_depth = 1.5;  

// ==========================================================================
// MODULES: HARDWARE & ROLLERS
// ==========================================================================

module Roller() {
    difference() {
        cylinder(d=roller_dia, h=roller_length, center=true, $fn=60);
        cylinder(d=roller_bore_dia, h=roller_length + 2, center=true, $fn=30);
    }
}

module PrintableRoller() {
    translate([0, 0, roller_length / 2])
    Roller();
}

module InnerMountingHoles(height) {
    step = 360 / hole_count;
    for(i = [0 : step : 359]) {
        rotate([0, 0, i]) translate([inner_hole_radius, 0, 0]) {
            translate([0, 0, -1]) 
                cylinder(d=hole_dia_m3_clear, h=height + 2, $fn=30);
            translate([0, 0, -1]) 
                cylinder(d=countersink_dia, h=countersink_depth + 1, $fn=30);
        }
    }
}

module OuterMountingHoles(height) {
    step = 360 / hole_count;
    for(i = [0 : step : 359]) {
        rotate([0, 0, i]) translate([outer_hole_radius, 0, 0]) {
            translate([0, 0, -1]) 
                cylinder(d=hole_dia_m3_clear, h=height + 2, $fn=30);
            translate([0, 0, -1]) 
                cylinder(d=countersink_dia, h=countersink_depth + 1, $fn=30);
        }
    }
}

// ==========================================================================
// MODULES: SPLIT RING STRUCTURES
// ==========================================================================

module OuterRingHalf() {
    half_height = bearing_height / 2;
    difference() {
        cylinder(r=bearing_od/2, h=half_height);
        
        translate([0, 0, -1])
        cylinder(r=race_radius + (ring_gap / 2), h=half_height + 2);
        
        translate([0, 0, half_height])
        rotate_extrude() {
            translate([race_radius, 0, 0])
            rotate([0, 0, 45])
            square([roller_dia + roller_slop, roller_dia + roller_slop], center=true);
        }
        
        // NEW: Relief Chamfer (Outer Ring Inner Edge)
        // Removes material at the bottom face to prevent tilt-binding
        translate([0, 0, -0.1])
        cylinder(r1=race_radius + (ring_gap / 2) + relief_chamfer, 
                 r2=race_radius + (ring_gap / 2), 
                 h=relief_chamfer + 0.1);
        
        OuterMountingHoles(half_height);
    }
}

module InnerRingHalf(has_spikes = false) {
    half_height = bearing_height / 2;
    axle_dia = roller_bore_dia - axle_clearance;
    
    difference() {
        union() {
            difference() {
                cylinder(r=race_radius - (ring_gap / 2), h=half_height);
                
                translate([0, 0, -1]) 
                    cylinder(r=bearing_id/2, h=half_height + 2);
                
                translate([0, 0, half_height])
                rotate_extrude() {
                    translate([race_radius, 0, 0])
                    rotate([0, 0, 45])
                    square([roller_dia + roller_slop, roller_dia + roller_slop], center=true);
                }
            }
            
            if (has_spikes) {
                step = 360 / roller_count;
                for(i = [0 : step : 359]) {
                    rotate([0, 0, i])
                    translate([race_radius - (roller_dia/2 * 0.707) - (roller_slop/2), 0, half_height - (roller_dia/2 * 0.707) - (roller_slop/2)])
                    rotate([0, 45, 0]) 
                    translate([0, 0, -2]) 
                    cylinder(d=axle_dia, h=roller_length + 1.5, $fn=30);
                }
            }
        }
        
        // NEW: Relief Chamfer (Inner Ring Outer Edge)
        // Subtracts a conical wedge from the outside edge of the inner ring
        translate([0, 0, -0.1])
        difference() {
            cylinder(r=bearing_od, h=relief_chamfer + 0.1);
            cylinder(r1=race_radius - (ring_gap / 2) - relief_chamfer, 
                     r2=race_radius - (ring_gap / 2), 
                     h=relief_chamfer + 0.1);
        }
        
        InnerMountingHoles(half_height);
    }
}

// ==========================================================================
// FLAT PRINT LAYOUT (Optimized for 256x256 mm bed)
// ==========================================================================

// 1. Outer Ring Bottom Half
translate([-64, 64, 0]) color("SteelBlue") OuterRingHalf();

// 2. Outer Ring Top Half
translate([64, 64, 0]) color("CornflowerBlue") OuterRingHalf();

// 3. Inner Ring Bottom Half WITH SPIKES
translate([-64, -64, 0]) color("SlateGray") InnerRingHalf(has_spikes=true);

// 4. Inner Ring Top Half NO SPIKES
translate([64, -64, 0]) color("LightSlateGray") InnerRingHalf(has_spikes=false);

// 5. Nest 6 Rollers
translate([-64, 64, 0]) {
    for(i = [0 : 5]) {
        rotate([0, 0, i * 60])
        translate([25, 0, 0])
        color("Orange") PrintableRoller();
    }
}

// 6. Nest 6 Rollers
translate([64, 64, 0]) {
    for(i = [0 : 5]) {
        rotate([0, 0, i * 60])
        translate([25, 0, 0])
        color("Orange") PrintableRoller();
    }
}