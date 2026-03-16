// Required variable inherited from the main file for positional logic
shroud_width = 32;

// --- NEW SHAPE CONTROL VARIABLES ---
partial_sphere_percent    = 10;    // [0:100] 100% = Full solid shell. 0% = Naked (only border ring). 20% = Partial struts.
partial_sphere_segments   = 8;     // Number of parallel struts/segments radiating from the center. Try 4 to 8.
rotor_ring_height         = 4;     // The bottom rim height that remains solid regardless of cover percentage
rotor_radius              = 62;    // Overall radius of the wheel
rotor_elongation          = 0.60;  // 1.0 = perfect hemisphere. > 1.0 = elongated/stretched outwards. < 1.0 = flattened dome.
rotor_ls_mount_radius     = 53.6-13; // Distance from center to the lazy susan pillars (closer/further from center)
rotor_ls_pillar_extension = 0;     // Positive = pillars extend PAST the flat rim. Negative = pillars are recessed/extracted inside.

// --- RIM CONTROL VARIABLES ---
rotor_rim_thickness       = 4;     // Independent thickness of the rim at the very bottom edge (Z=0)
rotor_rim_height          = 4;     // How far up the inside of the sphere the thickened rim extends

// --- HEMISPHERE ROTOR PARAMETERS ---
rotor_outer_diameter = rotor_radius * 2; 
rotor_thickness      = 3;   // Shell wall thickness
rotor_inner_diameter = rotor_outer_diameter - (rotor_thickness * 2);

// Motor Hub (Pololu Aluminum Hub Interface)
rotor_hub_outer_dia     = 24;   // Diameter of the plastic center hub
rotor_hub_z_offset      = 11;   // The gap from the open rim (Z=0) to the flat mating face of the hub
pololu_bcd              = 12.7; // Bolt Circle Diameter of the 4 M3 holes on the metal hub
pololu_insert_dia       = 4.2;  // Hole diameter for M3 heat-set insert (Adjust to your specific inserts)
pololu_insert_depth     = 5.5;  // Depth of the hole for the insert into the plastic
pololu_pin_rotation     = 45;   // Rotational alignment of the 4 holes
pololu_center_clearance = 4;    // Center bore diameter to ensure motor shaft spins freely

// Internal Webbing (Spokes)
rotor_spoke_thickness  = 2;   
rotor_spoke_length     = 62;  // Distance the internal ribs extend from the center (in mm)

// Lazy Susan Mounting 
rotor_ls_hole_dia        = 4.5; // Bottom clearance hole for M4 screw threads
rotor_ls_access_hole_dia = 9.0; // Top clearance hole for screwdriver & screw head
rotor_ls_standoff_dia    = 10;  // Diameter of the mounting pillar
rotor_ls_standoff_height = 6;   // Total thickness of plastic the screw bites into before the head seats
rotor_ls_rotation        = -14; // Matches the stator

$fn = 120;

// ==========================================
// MODULE DEFINITIONS
// ==========================================
// The Outer Drive Shell
module HemisphereRotor() {
    // Dynamic height calculation to ensure internal structures always hit the ceiling
    max_z_reach = rotor_outer_diameter * max(1, rotor_elongation);
    
    difference() {
        union() {
            // 1. The Main Outer Shell (Elongated via scale)
            difference() {
                union() { // Group the shell and the rim so the area blocks cut both
                    difference() {
                        scale([1, 1, rotor_elongation]) sphere(d = rotor_outer_diameter);
                        scale([1, 1, rotor_elongation]) sphere(d = rotor_inner_diameter);
                        
                        // Chop off the bottom half completely so it sits flat at Z=0
                        translate([0, 0, -max_z_reach / 2])
                            cube(max_z_reach + 5, center = true);
                    }
                    
                    // Independent Thickened Rim
                    rim_extra = rotor_rim_thickness - rotor_thickness;
                    if (rim_extra > 0) {
                        rotate_extrude() {
                            polygon([
                                [rotor_outer_diameter/2 - rotor_rim_thickness, 0],                            // Bottom-Inner
                                [rotor_outer_diameter/2, 0],                                                  // Bottom-Outer
                                [rotor_outer_diameter/2, rotor_rim_height],                                   // Top-Outer
                                [rotor_outer_diameter/2 - rotor_thickness, rotor_rim_height],                 // Top-Inner (meets the shell)
                                [rotor_outer_diameter/2 - rotor_rim_thickness, rotor_rim_height - rim_extra]  // 45-deg overhang slope
                            ]);
                        }
                    }
                } // End of Shell + Rim Union
                    
                // Dynamic Shell Coverage (Constant width struts aligned to internal webbing)
                if (partial_sphere_percent < 100) {
                    rotate([0, 0, rotor_ls_rotation]) {
                        // Map the percentage directly to a linear width
                        strut_width = rotor_outer_diameter * (partial_sphere_percent / 100);
                        cut_size = rotor_outer_diameter + 10; // Padding to guarantee clean cuts

                        // Use a 2D extrusion of the negative space to cleanly cut N segments
                        translate([0, 0, rotor_ring_height])
                        linear_extrude(height = cut_size) {
                            difference() {
                                // Start with a solid circle covering the whole area
                                circle(d = cut_size);

                                // Subtract out the positive struts (so they are preserved in the 3D cut)
                                for (i = [0 : partial_sphere_segments - 1]) {
                                    rotate(i * (360 / partial_sphere_segments))
                                    translate([0, -strut_width / 2])
                                    square([cut_size / 2, strut_width]);
                                }
                            }
                        }
                    }
                }
            }
            
            // 2. Internal Structure
            // The intersection forces all geometry to cleanly blend into the curved dome ceiling
            intersection() {
                scale([1, 1, rotor_elongation]) sphere(d = rotor_inner_diameter);
                union() {
                    // Central Printed Hub (Extends up to the ceiling)
                    translate([0, 0, rotor_hub_z_offset])
                        cylinder(d = rotor_hub_outer_dia, h = max_z_reach);
                        
                    // Standoffs for Lazy Susan Mounting (Inside the dome)
                    rotate([0, 0, rotor_ls_rotation]) {
                        for (pos = [ [0, rotor_ls_mount_radius], [0, -rotor_ls_mount_radius], [rotor_ls_mount_radius, 0], [-rotor_ls_mount_radius, 0] ]) {
                            translate([pos[0], pos[1], max(0, -rotor_ls_pillar_extension)]) {
                                cylinder(d = rotor_ls_standoff_dia, h = max_z_reach);
                            }
                        }
                        
                        // Solid Structural Ribs linking standoffs to the hub (Updated to match segment count)
                        translate([0, 0, rotor_hub_z_offset]) {
                            linear_extrude(height = max_z_reach) {
                                for (i = [0 : partial_sphere_segments - 1]) {
                                    rotate(i * (360 / partial_sphere_segments))
                                    translate([0, -rotor_spoke_thickness / 2])
                                    square([rotor_spoke_length, rotor_spoke_thickness]); // Updated to use new length variable
                                }
                            }
                        }
                    }
                }
            }
            
            // 3. Lazy Susan Pillar Extensions
            if (rotor_ls_pillar_extension > 0) {
                rotate([0, 0, rotor_ls_rotation]) {
                    for (pos = [ [0, rotor_ls_mount_radius], [0, -rotor_ls_mount_radius], [rotor_ls_mount_radius, 0], [-rotor_ls_mount_radius, 0] ]) {
                        translate([pos[0], pos[1], -rotor_ls_pillar_extension])
                            cylinder(d = rotor_ls_standoff_dia, h = rotor_ls_pillar_extension + 0.1); 
                    }
                }
            }
        }
        
        // Subtractions
        // 1. Motor Shaft Clearance Bore 
        clearance_bore_height = ((rotor_inner_diameter / 2) * rotor_elongation) - (rotor_hub_z_offset - 1);
        
        translate([0, 0, rotor_hub_z_offset - 1])
            cylinder(d = pololu_center_clearance, h = max(0.1, clearance_bore_height));
        
        // 2. Lazy Susan Screw Channels & Access Holes
        rotate([0, 0, rotor_ls_rotation]) {
            for (pos = [ [0, rotor_ls_mount_radius], [0, -rotor_ls_mount_radius], [rotor_ls_mount_radius, 0], [-rotor_ls_mount_radius, 0] ]) {
                translate([pos[0], pos[1], 0]) {
                    pillar_bottom_z = -rotor_ls_pillar_extension;
                    
                    translate([0, 0, pillar_bottom_z - 1])
                        cylinder(d = rotor_ls_hole_dia, h = rotor_ls_standoff_height + 2);
                    
                    translate([0, 0, pillar_bottom_z + rotor_ls_standoff_height]) 
                        cylinder(d = rotor_ls_access_hole_dia, h = max_z_reach * 2);
                }
            }
        }

        // 3. Holes for M3 Heat-Set Inserts (Pololu Hub Interface)
        for (i = [0:3]) {
            rotate([0, 0, i * 90 + pololu_pin_rotation])
            // Shift down slightly to ensure a clean boolean cut at the mating face
            translate([pololu_bcd / 2, 0, rotor_hub_z_offset - 0.1])
                cylinder(d = pololu_insert_dia, h = pololu_insert_depth + 0.1);
        }
    }
}

// ==========================================
// WASHER GENERATOR
// ==========================================
module PillarWashers() {
    spacing = rotor_ls_standoff_dia + 4; // Padding between washers
    thicknesses = [1, 1.5, 2];

    for (row = [0 : 2]) {
        for (col = [0 : 3]) {
            // Center the 4x3 grid relative to itself
            translate([
                col * spacing - (1.5 * spacing), 
                row * spacing - spacing, 
                0 // Positioned flat on the bed for printing
            ])
            difference() {
                cylinder(d = rotor_ls_standoff_dia, h = thicknesses[row]);
                
                // Clearance hole
                translate([0, 0, -1])
                    cylinder(d = rotor_ls_hole_dia, h = thicknesses[row] + 2);
            }
        }
    }
}

// ==========================================
// MAIN GEOMETRY (WHEEL & WASHERS)
// ==========================================

// Generate Prototype Hemisphere Rotor
translate([0, 0, -shroud_width/2]) HemisphereRotor();

// Generate 3 Sets of 4 Washers (1mm, 1.5mm, 2mm)
// Shifted to the side and dropped down to match the rotor's Z-height so they all sit flat on the bed
// translate([rotor_radius + 30, 0, -shroud_width/2]) PillarWashers();