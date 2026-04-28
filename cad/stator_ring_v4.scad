// Rollie Mk. I - Fully Parametric Segmented Stator
// All dimensions in metric (millimeters)

// --- MAIN BODY VARIABLES ---
hub_depth             = 50;  // Central hub depth (Z-axis)
webbing_depth         = 30;  // Structural webbing depth (Z-axis)
hub_outer_diameter    = 26;  // Outer diameter of the central hub
hub_rotation          = 13;   // Rotation of the inner hub and its features (degrees)

// Shroud (Outer Cylinder) Variables
shroud_width          = 40;  // Width of the outer cylinder (Z-axis)
shroud_outer_diameter = 120;
shroud_thickness      = 12;  // Thickness of the outer wall
// Auto-calculate the inner diameter based on the thickness
shroud_inner_diameter = shroud_outer_diameter - (shroud_thickness * 2); 

strut_thickness       = 4;   // Width of the 3 radial connecting struts

// --- SEGMENT SPECIFIC VARIABLES (INDIVIDUAL CONTROL) ---
// Camera Window: Top Left (SUBTRACTIVE)
brace1_length    = 25; // Tangential width of the camera window
brace1_thickness = 12; // Depth of the cut (punches through the 12mm shroud)
brace1_offset    = 65; // Extends past the 60mm outer radius for a clean cut
brace1_width     = 27; // Width of the camera window in the Z-axis

// Camera Cable Hole: Top Left
hole1_length      = 12;   // Tangential length of the cable hole
hole1_thickness   = 10;   // Radial depth of the cut
hole1_offset      = 62;   // Distance from center to outer edge of brace
hole1_width       = 25; // Cutout width for the ribbon cable (Z-axis)
hole1_x_offset    = 0;    // Horizontal shift (X-axis)
hole1_y_offset    = -15;  // Horizontal shift (Y-axis)
hole1_z_offset    = 0;    // Vertical shift (negative moves it down towards the bottom)

// Camera Cable Routing Hole (SUBTRACTIVE)
hole2_length      = 28;   
hole2_thickness   = 2;    
hole2_offset      = -46;  
hole2_cable_width = 16.8; 
hole2_x_offset    = 0;    
hole2_y_offset    = 0;    
hole2_z_offset    = 0;    

// Components Bay: Top Left
brace2_length    = 80;
brace2_thickness = 3;
brace2_offset    = 32; // Distance from center to outer edge of brace

// Components Bay: Top Right
brace3_length    = 80;
brace3_thickness = 5;
brace3_offset    = 49.5 - 15;

// Screen Bay: Top Right (SUBTRACTIVE)
brace4_length    = 68.4;
brace4_thickness = 27;
brace4_offset    = 61.5;
brace4_width     = 34;   // Z-axis width of the screen bay

// Components Bay: Bottom
brace5_length    = 70;
brace5_thickness = 3;
brace5_offset    = 37;

// --- MOTOR PARAMETERS ---
motor_width    = 12.4;
motor_height   = 10.4;
motor_depth    = 30;   // Depth of the cavity subtraction
motor_z_offset = 16;   // Distance from Z-center for top/bottom motors

// --- WIRE WINDOW PARAMETERS ---
wire_window_width    = 15;
wire_window_depth    = 8;
wire_window_height   = 20;
wire_window_y_offset = -9; // Shift along the Y axis

// --- LAZY SUSAN MOUNTING PARAMETERS ---
lazy_susan_hole_spacing  = 75.8; // Distance between hole centers (forming a square)
lazy_susan_hole_diameter = 5.6;  // Sized for M4 heat-set brass inserts
lazy_susan_hole_depth    = 10;   // Plenty of depth for a standard 8mm insert + screw clearance
lazy_susan_rotation      = -14;    // Rotation offset in degrees (0 = diamond, 45 = square)

$fn = 120;

// ==========================================
// MODULE DEFINITIONS
// ==========================================
module BraceSegment(rot, length, thickness, distance_from_center) {
    rotate([0, 0, rot])
    // The "distance" is measured from the center to the OUTER face of the bar
    translate([distance_from_center - thickness, -length/2])
    square([thickness, length]);
}

// Module for carving the dovetail trench
module MotorDovetailTrench() {
    linear_extrude(height = motor_depth, center = true) {
        polygon(points=[
            [-motor_width/2, -motor_height/2],
            [motor_width/2, -motor_height/2],
            [motor_width/2, -8.2], // Base of dovetail (16.4mm wide)
            [hub_outer_diameter/2 + 1, -motor_width/2], // Top of dovetail (12.4mm wide)
            [hub_outer_diameter/2 + 1, motor_width/2],
            [motor_width/2, 8.2],
            [motor_width/2, motor_height/2],
            [-motor_width/2, motor_height/2]
        ]);
    }
}

// Printable Dovetail Caps (For locking the motors in place)
// These are generated outside the main body, laying flat on the build plate for easy printing
module DovetailCap() {
    cap_tol = 0.15; // 0.15mm tolerance per side for a perfect slide-fit
    // Calculate the precise length of the trench inside the physical hub
    cap_length = (hub_depth / 2) - (motor_z_offset - (motor_depth / 2));
    
    intersection() {
        linear_extrude(height = cap_length) {
            polygon([
                [0, -8.2 + cap_tol],
                [7.8, -6.2 + cap_tol],
                [7.8, 6.2 - cap_tol],
                [0, 8.2 - cap_tol]
            ]);
        }
        // Curved outer face to perfectly match the 26mm hub radius
        translate([-motor_width/2, 0, -1]) 
            cylinder(d = hub_outer_diameter, h = cap_length + 2);
    }
}

// ==========================================
// MAIN GEOMETRY
// ==========================================
difference() {
    union() {
        // 1. Central Hub
        color("silver")
        rotate([0, 0, hub_rotation])
        linear_extrude(height = hub_depth, center = true) {
            circle(d = hub_outer_diameter);
        }

        // 2a. Outer Shroud (Cylinder)
        color("darkgray")
        linear_extrude(height = shroud_width, center = true) {
            difference() {
                circle(d = shroud_outer_diameter);
                circle(d = shroud_inner_diameter);
            }
        }

        // 2b. Structural Webbing (Internal Struts and Braces)
        color("gray")
        linear_extrude(height = webbing_depth, center = true) {
            union() {
                // Radial Struts (Fixed at 120° intervals)
                eps = 0.1; // Overlap value to fix manifold issues
                for (i = [0 : 2]) {
                    rotate([0, 0, 90 + (i * 120)])
                    // Shift inward by eps, dynamically center the strut, increase length by 2*eps
                    translate([(hub_outer_diameter/2) - eps, -(strut_thickness / 2)]) 
                    square([(shroud_inner_diameter/2) - (hub_outer_diameter/2) + (2 * eps), strut_thickness]);
                }
                
                // --- INDIVIDUAL SEGMENT CONTROL (ADDITIVE ONLY) ---
                
                // Components Bay: Top Left
                BraceSegment(150, brace2_length, brace2_thickness, brace2_offset);
                // Components Bay: Top Right
                BraceSegment(30, brace3_length, brace3_thickness, brace3_offset);
                // Components Bay: Bottom
                BraceSegment(270, brace5_length, brace5_thickness, brace5_offset);
            }
        }
    }

    // 3 & 4. Hub Subtractions (Rotated with the inner hub)
    rotate([0, 0, hub_rotation]) {
        // 3. Subtractions (Motor Cavities with Sliding Dovetail Trench)
        translate([0, 0,  motor_z_offset]) MotorDovetailTrench();
        translate([0, 0, -motor_z_offset]) MotorDovetailTrench();

        // 4. Wire Window (Strictly contained in Hub)
        translate([0, wire_window_y_offset, 0]) cube([wire_window_width, wire_window_depth, wire_window_height], center = true);
    }

    // 5. Lazy Susan Mounting Holes (Top and Bottom edges)
    eps = 0.1; // Small value to guarantee clean manifold subtractions
    lazy_susan_radius = lazy_susan_hole_spacing / sqrt(2);
    
    // Wrap the hole generation in a rotate block linked to the new variable
    rotate([0, 0, lazy_susan_rotation]) {
        // Coordinates: Top, Bottom, Right, Left
        for (pos = [ [0, lazy_susan_radius], [0, -lazy_susan_radius], [lazy_susan_radius, 0], [-lazy_susan_radius, 0] ]) {
            
            // Top edge holes (drilling down from the top of the shroud)
            translate([
                pos[0], 
                pos[1], 
                (shroud_width / 2) - lazy_susan_hole_depth + eps
            ])
            cylinder(h = lazy_susan_hole_depth + eps, d = lazy_susan_hole_diameter);

            // Bottom edge holes (drilling up from the bottom of the shroud)
            translate([
                pos[0], 
                pos[1], 
                -(shroud_width / 2) - eps
            ])
            cylinder(h = lazy_susan_hole_depth + eps, d = lazy_susan_hole_diameter);
        }
    }

    // 6. Screen Bay Subtraction (Top Right)
    // Extruded to exactly brace4_width to control its size independently
    linear_extrude(height = brace4_width, center = true) {
        BraceSegment(30, brace4_length, brace4_thickness, brace4_offset);
    }
    
    // 7. Camera Cable Subtraction (Top Left)
    // Punches through the outer shroud to allow the camera cable in, offset along X, Y, and Z axes
    translate([hole1_x_offset, hole1_y_offset, hole1_z_offset]) {
        linear_extrude(height = hole1_width, center = true) {
            BraceSegment(150, hole1_length, hole1_thickness, hole1_offset);
        }
    }
    
    // 8. Camera Window Subtraction (Top Left)
    // Punches through the outer shroud entirely
    linear_extrude(height = brace1_width, center = true) {
        BraceSegment(150, brace1_length, brace1_thickness, brace1_offset);
    }
    
    // 9. Camera Cable Routing Hole Hole Subtraction (Top)
    // Punches a hole based on the Components Bay: Bottom, offset along X, Y, and Z axes
    translate([hole2_x_offset, hole2_y_offset, hole2_z_offset]) {
        linear_extrude(height = hole2_cable_width, center = true) {
            BraceSegment(270, hole2_length, hole2_thickness, hole2_offset);
        }
    }
}

// Generate two caps off to the side of the main stator
// Shifted down to the Z-floor so they sit perfectly flat on the slicer bed alongside the main body
translate([80, 20, -shroud_width/2]) DovetailCap();
translate([80, -20, -shroud_width/2]) DovetailCap();