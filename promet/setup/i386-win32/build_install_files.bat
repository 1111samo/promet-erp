md ..\..\output
md ..\..\output\%1
md ..\..\output\%1\plugins
lazbuild --build-mode=Default -q ..\..\source\tools\wizardmandant.lpi
If errorlevel 1 lazbuild --build-mode=Default -q ..\..\source\tools\wizardmandant.lpi
If errorlevel 1 goto end
lazbuild -q -B ..\..\source\messagemanager\messagemanager.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\messagemanager\messagemanager.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\promet.erp\prometerp.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\promet.erp\prometerp.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\statistics\statistics.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\statistics\statistics.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\meeting\meeting.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\meeting\meeting.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\cmdwizardmandant.lpi
If errorlevel 1 lazbuild -q -B ..\..\source\tools\cmdwizardmandant.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\pstarter.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\pstarter.lpi
lazbuild --build-mode=Default -q ..\..\source\scripts\pscript.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\scripts\pscript.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\linksender.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\linksender.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\checkout.lpi
If errorlevel 1 lazbuild --build-mode=Default -B -q ..\..\source\tools\checkout.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\checkin.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\tableedit.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\tableedit.lpi
If errorlevel 1 goto end

lazbuild --build-mode=Default -q ..\..\source\timeregistering\timeregistering.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\timeregistering\timeregistering.lpi
If errorlevel 1 goto end

lazbuild --build-mode=Default -q ..\..\source\sync\sync_db.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\sync_outlook_contacts.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\sync_outlook_calendar.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\sync_outlook_tasks.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\pop3receiver.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\smtpsender.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\feedreceiver.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\sync\twitterreceiver.lpi
If errorlevel 1 goto end

lazbuild --build-mode=Default -q ..\..\source\plugins\oofile\oofile.lpi
lazbuild --build-mode=Default -q ..\..\source\plugins\dwgfile\dwgfile.lpi
lazbuild --build-mode=Default -q ..\..\source\plugins\solidworks\solidworks.lpi
lazbuild --build-mode=Default -q ..\..\source\plugins\vectorfile\vectorfile.lpi
lazbuild --build-mode=Default -q ..\..\source\plugins\winthumb\winthumb.lpi

lazbuild --build-mode=Default -q ..\..\source\tools\portableapps.lpi
lazbuild --build-mode=Default -q ..\..\source\tools\cdmenue.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\cdmenue.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\helpviewer.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\helpviewer.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\archivestore.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\archivestore.lpi
If errorlevel 1 goto end
lazbuild --build-mode=Default -q ..\..\source\tools\clientmanagement.lpi
If errorlevel 1 lazbuild --build-mode=Default -q -B ..\..\source\tools\clientmanagement.lpi
If errorlevel 1 goto end
goto realend
:end
echo Compile done (or failed)...
pause
:realend
