// ==========================================
// TESTING STAND MODULE (SUPPORT-FREE)
// ==========================================
stand_center_height  = 85;  // Height of the robot's center axis (gives 23mm ground clearance)
stand_cradle_dia     = 121; // 1mm extra clearance so the 120mm shroud drops in easily
stand_thickness      = 25;  // Narrower than the 33mm shroud to prevent rubbing
stand_base_x         = 130; // Footprint width for stability
stand_base_y         = 60;  // Footprint depth for stability

// --- NEW HEIGHT CONTROL ---
stand_support_height = 35;  // How far up the side of the robot the prongs reach from the bottom of the curve (Max is 60.5)

module TestingStand() {
    // Calculate the absolute Z height of the lowest point of the cradle curve
    cradle_bottom_z = stand_center_height - (stand_cradle_dia / 2);
    prong_top_z = cradle_bottom_z + stand_support_height;
    
    difference() {
        // Main Positive Geometry
        union() {
            // Flat Base Plate (Rests flush at Z=0)
            translate([0, 0, 2.5])
                cube([stand_base_x, stand_base_y, 5], center = true);
            
            // Upright Support Block
            translate([0, 0, stand_center_height / 2])
                cube([stand_cradle_dia + 16, stand_thickness, stand_center_height], center = true);
        }
        
        // Subtractions
        // 1. The U-Shape Cradle Cutout
        translate([0, 0, stand_center_height])
            rotate([90, 0, 0])
            cylinder(d = stand_cradle_dia, h = stand_thickness + 2, center = true, $fn=120);
            
        // 2. Dynamic Chop-off to control prong height
        // We place a massive subtraction cube directly at the exact Z-height where the prongs should end
        translate([0, 0, prong_top_z + 50])
            cube([stand_base_x + 50, stand_thickness + 2, 100], center = true);
    }
}

// Render the stand centered perfectly at the origin for slicing
TestingStand();