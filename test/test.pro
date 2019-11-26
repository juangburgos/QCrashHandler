QT += core
QT -= gui

TEMPLATE = app

CONFIG += c++11
CONFIG -= flat
CONFIG += console
CONFIG -= app_bundle

CONFIG(debug, debug|release) {
	TARGET = testd
} else {
	TARGET = test
	# create debug symbols for release builds
	# NOTE : need to disable optimization, else dump files will point to incorrect source code lines
	CONFIG *= force_debug_info
	QMAKE_CXXFLAGS_RELEASE_WITH_DEBUGINFO -= -O2
}

include($$PWD/../src/qcrashhandler.pri)

SOURCES += main.cpp

include($$PWD/../src/qpostprocess.pri)


