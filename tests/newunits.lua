local symmath = require 'symmath'
symmath.simplifyConstantPowers = true

local c = symmath.Variable('c', nil, true)
local m = symmath.Variable('m', nil, true)
local s = symmath.Variable('s', nil, true)
local G = symmath.Variable('G', nil, true)
local kg = symmath.Variable('kg')

local c_from_m_s = (c):equals(299792458 * m / s)
print(c_from_m_s)

-- c = 1, solve for s
--local s_from_m = c_from_m_s:replace(c, 1):solve(s)
local s_from_m = (c_from_m_s:replace(c, 1) * s):simplify()
print(s_from_m)

local G_from_m_s_kg = G:equals(6.67384e-11 * m^3 / (kg * s^2))
print(G_from_m_s_kg)

local kg_from_m = (G_from_m_s_kg:replace(G, 1):subst(s_from_m) * kg):simplify()
print(kg_from_m)

-- local m_from_kg = kg_from_m:solve(m)
local m_from_kg = (kg * (1 / (kg_from_m / m))):simplify()
print(m_from_kg)

--local s_from_kg = s_from_m:subst(kg_from_m:solve(kg))
local s_from_kg = s_from_m:subst(m_from_kg):simplify()
print(s_from_kg)

--[[

c = 1 = 299792458 * m * s^-1
G = 1 = 6.67384e-11 * m^3 * kg^-1 * s^-2
hBar = 1 = 1.05457173e-34 * m^2 * kg * s^-1
kB = 1 = 1.3806488e-23 * m^2 * kg * s^-2 * K-1
 
c relates m to s:
    1 = 299792458 * m * s^-1
    s = 299792458 * m
    ...
    substitute G's m
    s = 299792458 * 6.187355886101e+34
    s = 1.854922629615e+43
G relates kg to m and s
    1 = 6.67384e-11 * m^3 * kg^-1 * s^-2
    kg = 6.67384e-11 * m^3 * s^-2
    kg = 6.67384e-11 / 299792458^2 * m
    kg = 7.4256484500929e-28 * m
    ...
    substitute hBar's kg
    m = 45945129.645799 / 7.4256484500929e-28
    m = 45945129.645799 / 7.4256484500929e-28
    m = 6.187355886101e+34
hBar relates kg to m^-1 and s
    1 = 1.05457173e-34 * m^2 * s^-1 * kg
    kg = 1.05457173e-34^-1 * (m/s)^-1 * m^-1
    kg = 299792458 / 1.05457173e-34 * m^-1
    kg = 2.8427886835161e+42 * m^-1
    ...
    substitute G's m in terms of kg...
    m^-1 = 7.4256484500929e-28 * kg^-1
    substitute hBar's m^-1 in terms of kg...
    kg = 2.8427886835161e+42 * 7.4256484500929e-28 * kg^-1
    kg^2 = 2.1109549381693e+15
    kg = 45945129.645799
...and combining G and hBar relates kg to constants...
kB relates K to kg and m/s
    1 = 1.3806488e-23 * m^2 * kg * s^-2 * K-1
    K = 1.3806488e-23 / 299792458^2 * kg
    K = 1.5361789647104e-40 * kg
    ...
    substitute hBar's kg...
    K = 1.5361789647104e-40 * 45945129.645799
    K = 7.0579941692769e-33
 
... what relates V or A?
V = kg * m^2 * s^-3 * A^-1
V * A = (kg * m^2 * s^-1) * s^-2
V * A = 1/1.05457173e-34 * s^-2
V * A = 9.4825223505659e+033 * s^-2
V * A = 9.4825223505659e+033 / 1.854922629615e+43^2
V * A = 2.7559559767945e-053
... they at least relate to one another ...
 
 
Energy is measured in Joules = kg m^2 / s^2
    hBar says
    1 / 1.05457173e-34 = kg * m^2 * s^-1
    c says
    1 = 299792458 * m * s^-1
    combine to get
    1.05457173e-34^-1 * 299792458^-1 = (kg * m^2 * s^-2) * m
    1.05457173e-34^-1 * 299792458^-1 = J * m
    J = 1.05457173e-34^-1 * 299792458^-1 * m^-1
    J = 3.1630289880628e+025 * m^-1 
    m = 3.1630289880628e+025 * J^-1 
    ... there's distance in units of inverse energy
    c says
    m = 3.1630289880628e+025 * J^-1 * (299792458 * m * s^-1)
    s = 3.1630289880628e+025 * 299792458 * J^-1
    s = 3.1630289880628e+025 * 299792458 * J^-1
    s = 9.482522350566e+033 * J^-1
    ... there's time in units of inverse energy
    hBar says
    kg = 1.05457173e-34^-1 * s * m^-2
    kg = 1.05457173e-34^-1 * (9.482522350566e+033 * J^-1) * (3.1630289880628e+025 * J^-1)^-2
    kg = 1.05457173e-34^-1 * 9.482522350566e+033 * 3.1630289880628e+025^-2 * J
    kg = 8.9875517873681e+016 * J
 
 
new unit! electronvolt (eV)
    ... must be in terms of ratios of V and A
eV = 1.60217653e-19 * J
J = 6.2415094796077e+18 * eV
J = 6.2415094796077e+9 * GeV
 
result:
    m = 3.1630289880628e+025 / 6.2415094796077e+9 * GeV^-1
    s = 9.482522350566e+033 / 6.2415094796077e+9 * GeV^-1
    kg = 8.9875517873681e+016 * 6.2415094796077e+9 * GeV
    ...
    m = 5.0677308083839e+015 * GeV^-1
    s = 1.5192674755277e+024 * GeV^-1
    kg = 5.6095889679323e+026 * GeV
    ...
    µb = 1e-34 * m^2
    µb = 1e-34 * (5.0677308083839e+015 * GeV^-1)^2
    µb = 1e-34 * 5.0677308083839e+15^2 * GeV^-2
    µb = 0.0025681895546243 * GeV^-2
    µb / 0.0025681895546243 = GeV^-2
    GeV^-2 = 389.37935799925 µb

--]]
