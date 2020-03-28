function data = cvmlread(filename)

DOMnode = xmlread('Thermal_01.cvml')
out = xml2struct('Thermal_01.xml')