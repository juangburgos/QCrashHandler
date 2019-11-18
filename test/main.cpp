#include <QCoreApplication>
#include <QStandardPaths>

#include <QCrashHandler>

int buggyFunc() {
	delete reinterpret_cast<QString*>(0xFEE1DEAD);
	return 0;
}

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

	// write the dumps in the user's desktop:
	Breakpad::CrashHandler::instance()->Init(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation));

	// Test
	buggyFunc();

    return a.exec();
}
