Airports source file
====================

This directory needs to contain a file ``apt.dat`` with information about airport layouts. You can find the file in a FlightGear (out-of-date) or XPlane (newer) distribution; since they are derived from Robin Peel's original X-Plane scenery gateway, both should be GPL-compatible.

## Adding custom airports

Any files ending with ``.dat`` in the ``custom/`` subdirectory will also be included, so that you don't have to edit apt.dat directly. Best practice is to include one file for each airport, e.g. ``custom/CNN8.dat``. You can replace any airport in ``apt.dat`` if you wish (as long as it has the same identifier and appears in the same 10×10 degree bucket).
