// Samsung T7 desktop stand - dimensions in mm
// SSDs 85 x 57 x 8 mm stand landscape one behind another, split by thin
// dividers: front lip + tilted wedge support. Outer edges are rounded.
// Print base down, no supports needed. Axes: X - width, Y - front to back.
// Bottom has 4 pockets for 17 mm stick-on rubber feet.
$fn = 64;

// SSD
ssd_w = 85;
ssd_h = 57;
ssd_t = 8;
clr   = 0.5;        // clearance per side
show_ssd = true;    // draw the SSD in preview (F5); never goes to the STL

// Base plate
base_w = 100;
base_d = 72;
base_h = 6;
base_r = 4;         // corner radius in plan

// Edges
edge_r  = 1.5;      // rounding of outer edges
chamfer = 0.6;      // bottom edge chamfer, also hides elephant foot

// Front lip
lip_d = 12;
lip_h = 15;         // top above the table
lip_r = 5;          // top rounding

// Rear wedge
wedge_w    = 76;
wedge_h    = 40;    // ridge above the table
wedge_top  = 3;     // flat on the ridge
wedge_r    = 2;     // ridge rounding
wedge_back = 3;     // base margin behind the wedge

tilt = 20;          // SSD lean from vertical, deg
seat = 3.5;         // seat groove depth below base top, at its lowest point

slots = 2;          // SSDs one behind another
wall  = 5;          // divider between slots, full-round top

// Rubber feet: pockets in the bottom for stick-on bumpers
feet       = true;
foot_d     = 17;    // bumper diameter (Ozon 1381804965: 17 x 3 mm)
foot_h     = 3;     // bumper height
foot_depth = 1;     // pocket depth; the bumper sticks out by the rest
foot_inset = 12;    // pocket center from the base edges

// Preview only: the stand on a Mac mini M4 / M4 Pro (127 x 127 x 50 mm)
show_mac = true;
mac_w    = 127;
mac_h    = 50;

slot_w = ssd_w + 2*clr;
slot_t = ssd_t + 2*clr;
// Front-bottom edge of the slot bites slightly into the lip to avoid
// coincident faces
slot_y = lip_d - 0.5;
slot_z = base_h - seat + slot_t*sin(tilt);
// Y shift between slots: horizontal, so all slot floors stay level
slot_pitch = (slot_t + wall)/cos(tilt);

// Y of slot i's back plane (= face of the divider or wedge behind it) at height z
function back_y(z, i = 0) =
    slot_y + i*slot_pitch + slot_t*cos(tilt) + (z - (base_h - seat))*tan(tilt);

module footprint() {
    translate([-base_w/2 + base_r, base_r])
        offset(r = base_r) square([base_w - 2*base_r, base_d - 2*base_r]);
}

// Extrude a 2D profile drawn in (Y, Z) along X, centered
module along_x(w) {
    rotate([90, 0, 90]) linear_extrude(w, center = true) children();
}

// Sphere for rounding edges via minkowski
module ball(r) sphere(r, $fn = 24);

// Plate: rounded top edge, chamfered bottom edge
module base() {
    hull() {
        linear_extrude(0.01) offset(delta = -chamfer) footprint();
        translate([0, 0, chamfer]) linear_extrude(base_h - chamfer - edge_r) footprint();
        translate([0, 0, base_h - edge_r - 0.01]) minkowski() {
            linear_extrude(0.01) offset(delta = -edge_r) footprint();
            ball(edge_r);
        }
    }
}

// Bar along the front edge, ends follow the base corners. Built shrunk by
// edge_r, then grown back with a ball so every edge gets rounded.
module lip() {
    minkowski() {
        intersection() {
            along_x(base_w) offset(delta = -edge_r) hull() {
                square([lip_d, base_h]);
                translate([lip_r, lip_h - lip_r]) circle(lip_r);
                translate([lip_d - lip_r, lip_h - lip_r]) circle(lip_r);
            }
            linear_extrude(lip_h) offset(delta = -edge_r) footprint();
        }
        ball(edge_r);
    }
}

// Tilted plate between slot i and i + 1, full-round top
module divider(i) {
    r = wall/2;
    h = (wedge_h - (base_h - seat))/cos(tilt);  // along the slot from its floor
    translate([0, slot_y + i*slot_pitch, slot_z])
        rotate([-tilt, 0, 0])
            minkowski() {
                translate([-wedge_w/2 + r, slot_t + r, r])
                    cube([wedge_w - 2*r, 0.01, h - 2*r]);
                ball(r);
            }
}

// Rear support behind the last slot, rounded like the lip
module wedge() {
    k  = slots - 1;
    f  = 0.3;       // front face pushed forward, then trimmed by the slot
    zc = wedge_h - wedge_r;
    yc = back_y(zc, k) - f + wedge_r/cos(tilt);
    minkowski() {
        along_x(wedge_w - 2*edge_r) offset(delta = -edge_r) hull() {
            translate([back_y(0, k) - f, 0]) square([0.01, 0.01]);
            translate([base_d - wedge_back - 0.01, 0]) square([0.01, base_h]);
            translate([yc, zc]) circle(wedge_r);
            translate([yc + wedge_top, zc]) circle(wedge_r);
        }
        ball(edge_r);
    }
}

// SSD body with clearance, leaning back on the divider or wedge
module slot(i = 0) {
    translate([0, slot_y + i*slot_pitch, slot_z])
        rotate([-tilt, 0, 0])
            translate([-slot_w/2, 0, 0]) cube([slot_w, slot_t, 150]);
}

module feet_pockets() {
    for (sx = [-1, 1], y = [foot_inset, base_d - foot_inset])
        translate([sx*(base_w/2 - foot_inset), y, -1])
            cylinder(d = foot_d + 2*clr, h = foot_depth + 1);
}

// SSD dummy: X - length, Y - thickness, Z - height, USB-C on the +X end
module ssd() {
    r = 3;          // corner radius
    color("DimGray") difference() {
        hull() for (x = [-1, 1], z = [r, ssd_h - r])
            translate([x*(ssd_w/2 - r), 0, z])
                rotate([-90, 0, 0]) cylinder(r = r, h = ssd_t);
        translate([ssd_w/2, ssd_t/2, ssd_h/2]) cube([7, 3.4, 9], center = true);
    }
    // Status LED next to the port
    color("DodgerBlue") translate([ssd_w/2, ssd_t/2, ssd_h/2 + 9]) sphere(0.8);
    // USB-C plug and cable
    color("Black") translate([ssd_w/2, ssd_t/2, ssd_h/2]) rotate([0, 90, 0]) {
        hull() for (s = [-1, 1]) translate([s*2.75, 0, 0]) cylinder(d = 6.5, h = 22);
        cylinder(d = 4, h = 60);
    }
}

// SSD resting on the slot floor and leaning on the divider or wedge
module ssd_in_place(i = 0) {
    translate([0, slot_y + i*slot_pitch, slot_z])
        rotate([-tilt, 0, 0])
            translate([0, slot_t - ssd_t, 0]) ssd();
}

// Rubber bumpers stuck into the pockets, dome down
module rubber_feet() {
    color("#202020")
    for (sx = [-1, 1], y = [foot_inset, base_d - foot_inset])
        translate([sx*(base_w/2 - foot_inset), y, foot_depth - foot_h])
            cylinder(d1 = foot_d - 4, d2 = foot_d, h = foot_h);
}

// Port opening on a face normal to Y: rounded rect in XZ, r defaults to stadium
module port(w, h, r) {
    rr = is_undef(r) ? h/2 : r;
    hull() for (x = [-1, 1], z = [-1, 1])
        translate([x*(w/2 - rr), 0, z*(h/2 - rr)])
            rotate([90, 0, 0]) cylinder(r = rr, h = 1, center = true);
}

// Mac mini M4 / M4 Pro, centered, front to -Y, top at z = 0.
// Corner radius and port positions are approximate.
module mac_mini() {
    r    = 18;      // corner radius in plan
    foot = 4;       // dark plastic base under the aluminium shell
    pz   = -27;     // port centers
    module plan(inset = 0) offset(r = r - inset) square(mac_w - 2*r, center = true);

    translate([0, 0, -mac_h]) {
        color("#d6d7d9") translate([0, 0, foot]) linear_extrude(mac_h - foot) plan();
        color("#2a2a2a") linear_extrude(foot + 0.01) plan(6);
    }
    color("#111") {
        // Front: 2x USB-C 10 Gb/s, headphone jack
        for (p = [[-34, 8.9, 3.2], [-22, 8.9, 3.2], [-10, 3.6, 3.6]])
            translate([p[0], -mac_w/2, pz]) port(p[1], p[2], p[3]);
        // Back: power, Ethernet, HDMI, 3x Thunderbolt 5
        for (p = [[42, 12, 7, 2], [25, 14, 11, 1], [8, 14, 5, 1],
                  [-8, 8.9, 3.2], [-20, 8.9, 3.2], [-32, 8.9, 3.2]])
            translate([p[0], mac_w/2, pz]) port(p[1], p[2], p[3]);
    }
}

difference() {
    union() {
        base();
        lip();
        if (slots > 1) for (i = [0 : slots - 2]) divider(i);
        wedge();
    }
    for (i = [0 : slots - 1]) slot(i);
    if (feet) feet_pockets();
}

if (show_ssd && $preview) for (i = [0 : slots - 1]) ssd_in_place(i);
if (feet && $preview) rubber_feet();
if (show_mac && $preview)
    translate([0, base_d/2, foot_depth - foot_h]) mac_mini();
