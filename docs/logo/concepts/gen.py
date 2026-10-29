import math
def dollar(cx, cy, k, w, color):
    S=(f"M{cx+.34*k:.1f},{cy-.36*k:.1f} C{cx+.22*k:.1f},{cy-.54*k:.1f} {cx-.38*k:.1f},{cy-.54*k:.1f} {cx-.38*k:.1f},{cy-.22*k:.1f} "
       f"C{cx-.38*k:.1f},{cy+.04*k:.1f} {cx+.38*k:.1f},{cy-.06*k:.1f} {cx+.38*k:.1f},{cy+.22*k:.1f} "
       f"C{cx+.38*k:.1f},{cy+.54*k:.1f} {cx-.22*k:.1f},{cy+.54*k:.1f} {cx-.36*k:.1f},{cy+.36*k:.1f}")
    return (f'<path d="{S}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>'
            f'<path d="M{cx},{cy-.66*k:.1f}V{cy+.66*k:.1f}" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
def svg(body): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">{body}</svg>\n'
def arc_pts(cx,cy,r,a0,a1,n=60): return [(cx+r*math.cos(math.radians(a0+(a1-a0)*i/n)), cy+r*math.sin(math.radians(a0+(a1-a0)*i/n))) for i in range(n+1)]

# A: the trail draws the question mark, the coin is its dot.
cx,cy,r=128,86,50
a0,a1=160,385
p0=arc_pts(cx,cy,r,a0,a0)[0]; p1=arc_pts(cx,cy,r,a1,a1)[0]
hook=(f"M{p0[0]:.1f},{p0[1]:.1f} A{r},{r} 0 1 1 {p1[0]:.1f},{p1[1]:.1f} "
      f"C{p1[0]-14:.1f},{p1[1]+10:.1f} 128,140 128,160")
A=(f'<path d="{hook}" fill="none" stroke="#000" stroke-width="24" stroke-linecap="round" stroke-dasharray="18 44"/>'
   f'<circle cx="128" cy="214" r="32" fill="#000"/>'+dollar(128,214,30,6.5,"#fff"))
open("a-trail-question.svg","w").write(svg(A))

# B: the $ stroke dissolves into shrinking dots, drifting away.
B='<g>'+dollar(100,138,124,24,"#000")+'</g>'
# dots continue from the top terminal of the S, along a gentle curve to the right
sx,sy=100+.34*124,138-.36*124
import math as _m
ang=_m.radians(-28)
for i,rad in enumerate([11,8.5,6.5,4.5]):
    dist=34+i*24
    x=sx+_m.cos(ang)*dist; y=sy+_m.sin(ang)*dist+ i*i*2.5
    B+=f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad}" fill="#000"/>'
open("b-dollar-dissolves.svg","w").write(svg(B))

# C: a "where?" map pin holding a $, at the end of a dashed route.
pcx,pcy,pr=158,82,56; tipy=pcy+pr*1.9
pin=(f"M{pcx},{tipy:.1f} C{pcx-22},{tipy-34:.1f} {pcx-pr},{pcy+40} {pcx-pr},{pcy} "
     f"A{pr},{pr} 0 1 1 {pcx+pr},{pcy} C{pcx+pr},{pcy+40} {pcx+22},{tipy-34:.1f} {pcx},{tipy:.1f}Z")
C=(f'<path d="M34,214 C64,236 110,226 {pcx-6},{tipy+4:.1f}" fill="none" stroke="#000" stroke-width="15" stroke-linecap="round" stroke-dasharray="8 30"/>'
   f'<path d="{pin}" fill="#000"/>'+dollar(pcx,pcy,46,10,"#fff"))
open("c-where-pin.svg","w").write(svg(C))
print("ok")
