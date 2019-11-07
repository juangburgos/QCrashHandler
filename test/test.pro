QT += core
QT -= gui

CONFIG += c++11
CONFIG -= flat

TARGET = test
CONFIG += console
CONFIG -= app_bundle

TEMPLATE = app

include($$PWD/../src/qcrashhandler.pri)

QMAKE_LFLAGS_RELEASE += /MAP
QMAKE_CFLAGS_RELEASE += /Zi
QMAKE_LFLAGS_RELEASE += /debug /opt:ref

SOURCES += main.cpp

include($$PWD/../deps/add_qt_path.pri)