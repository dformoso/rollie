// Required variable inherited from the main file for positional logic
shroud_width = 32;

// --- NEW SHAPE CONTROL VARIABLES ---
partial_sphere_percent    = 8;      // [0:100] 100% = Full solid shell. 0% = Naked.
partial_sphere_segments   = 8;      // Number of parallel struts/segments radiating from center.
rotor_ring_height         = 4;      // The bottom rim height that remains solid
rotor_radius              = 62;     // Overall radius of the wheel
rotor_elongation          = 0.60;   // 1.0 = perfect hemisphere. > 1.0 = elongated. < 1.0 = flattened.
rotor_ls_mount_radius     = 53.6-13; // Distance from center to the lazy susan pillars
rotor_ls_pillar_extension = 0;      // Positive = pillars extend PAST the flat rim. 

// --- RIM CONTROL VARIABLES ---
rotor_rim_thickness       = 3;      // [THINNED] Reduced from 4mm
rotor_rim_height          = 4;      // How far up the inside of the sphere the thickened rim extends

// --- HEMISPHERE ROTOR PARAMETERS ---
rotor_outer_diameter = rotor_radius * 2; 
rotor_thickness      = 3;   // [THINNED] Shell wall thickness (Reduced from 3mm)
rotor_inner_diameter = rotor_outer_diameter - (rotor_thickness * 2);

// Motor Hub (Pololu Aluminum Hub Interface)
rotor_hub_outer_dia     = 18;   // [THINNED] Reduced from 24mm to save center mass
rotor_hub_z_offset      = 11;   // The gap from the open rim (Z=0) to the flat mating face
pololu_bcd              = 12.7; // Bolt Circle Diameter of the 4 M3 holes on the metal hub
pololu_hole_dia         = 3.0;  // 3mm holes for the hub mounting
pololu_hole_depth       = 10.0; // 10mm deep holes
pololu_pin_rotation     = 45;   // Rotational alignment of the 4 holes
pololu_center_clearance = 7;    // Center bore diameter to ensure motor shaft spins freely
pololu_center_depth     = 1;    // Distance the clearance bore extends downward from the hub face 
pololu_center_chamfer   = 1.5;  // Chamfer depth for the top exit hole (in mm)

// Internal Webbing (Spokes)
rotor_spoke_thickness  = 1.2;  // [THINNED] Reduced from 2mm
rotor_spoke_length     = 62;   // Distance the internal ribs extend from the center (in mm)

// Lazy Susan Mounting 
rotor_ls_hole_dia        = 4.5; // Bottom clearance hole for M4 screw threads
rotor_ls_access_hole_dia = 9.0; // Top clearance hole for screwdriver & screw head
rotor_ls_standoff_dia    = 10;  // Increased to 12mm so the 9mm access hole doesn't sever the ribs
rotor_ls_standoff_height = 6;   // Total thickness of plastic the screw bites into
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
                        
                        // Solid Structural Ribs linking standoffs to the hub
                        translate([0, 0, rotor_hub_z_offset]) {
                            linear_extrude(height = max_z_reach) {
                                for (i = [0 : partial_sphere_segments - 1]) {
                                    rotate(i * (360 / partial_sphere_segments))
                                    translate([0, -rotor_spoke_thickness / 2])
                                    square([rotor_spoke_length, rotor_spoke_thickness]); 
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
        // 1. Motor Shaft Clearance Bore & Top Chamfer
        translate([0, 0, rotor_hub_z_offset - pololu_center_depth])
            cylinder(d = pololu_center_clearance, h = max_z_reach);
            
        top_z = (rotor_outer_diameter / 2) * rotor_elongation;
        if (pololu_center_chamfer > 0) {
            translate([0, 0, top_z - pololu_center_chamfer])
                cylinder(d1 = pololu_center_clearance, 
                         d2 = pololu_center_clearance + (pololu_center_chamfer * 2), 
                         h = pololu_center_chamfer + 0.1);
        }
        
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
        
        // 3. Pololu Motor Hub Mounting Holes
        for (i = [0:3]) {
            rotate([0, 0, i * 90 + pololu_pin_rotation]) {
                translate([pololu_bcd / 2, 0, rotor_hub_z_offset - pololu_hole_depth])
                    cylinder(d = pololu_hole_dia, h = pololu_hole_depth + 0.1); 
            }
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

// Generate Prototype Hemisphere Rotor (Flat rim on the bed)
HemisphereRotor();

// Generate Pillar Washers (Shifted to the side to avoid overlapping the rotor)
//translate([rotor_outer_diameter + 20, 0, 0]) PillarWashers();