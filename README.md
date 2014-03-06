VGL to VFL Compiler [![Build Status](https://travis-ci.org/the-gss/vfl-compiler.png?branch=master)](https://travis-ci.org/the-gss/vgl-compiler)
=============

This library compiles [GSS](http://gridstylesheets.org/)'s [Visual Grid Language](http://gridstylesheets.org/guides/vfl/) (VGL) statements into [GSS-flavored VFL](http://gridstylesheets.org/guides/ccss/) statements.

## Background

The intention of VGL is feature parity with W3C's Grid Layout Module, but built atop of the constraint-based language primitives implemented in [GSS](http://gridstylesheets.org/) and established in Apple's [Visual Format Language](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/AutolayoutPG/VisualFormatLanguage/VisualFormatLanguage.html) (VFL) and Greg Badros's [Constraint CSS](http://citeseer.ist.psu.edu/viewdoc/summary?doi=10.1.1.101.4819) (CCSS).

CCSS is a language for defining constraints between element properties.

VFL is a language for 1-dimensional alignments of elements.

VGL is a language for creating 2-dimensional grid.

## Documentation

Please refer to <http://gridstylesheets.org/guides/vgl/>.