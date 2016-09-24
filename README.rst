iOS SDK for the PullString Web API
==================================

Overview
--------

This package provides a module to access the PullString Web API.

The PullString Web API lets you add text or audio conversational
capabilities to your apps, based upon content that you write in the
PullString Author environment and publish to the PullString Platform.

Library
-------

The iOS SDK is provided as a PullStringLibrary.xcodeproj project which
generates a static library, libPullStringLibrary.a. This library uses
NSUrlSession for HTTPS requests and NSJSONSerialization for producing
and parsing JSON data.

To use the library in your own code:

.. code-block:: objc

    #import "PullStringLibrary.h"

Sample Code
-----------

A PullStringTextClient.xcodeproj project is provided with a sample
project that embeds the PullStringLibrary project. This project
presents a text messaging style interface and lets you chat with any
PullString project. By default, the project is set up to connect with
the PullString "Rock, Paper, Scissors" sample project.

The PullStringTextClient project also includes a test script that
demonstrates how to exercise more the SDK.

The Xcode projects were produced using Xcode 8.

Documentation
-------------

The PullString Web API specification can be found at:

   http://docs.pullstring.com/docs/api

For more information about the PullString Platform, refer to:

   http://pullstring.com/
