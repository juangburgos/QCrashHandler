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
}

include($$PWD/../src/qpreprocess.pri)
include($$PWD/../src/qcrashhandler.pri)

SOURCES += main.cpp

include($$PWD/../src/qpostprocess.pri)


