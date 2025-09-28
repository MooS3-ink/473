# RedTeam Tool - RBG 

*Team:** ECHO

## Overview
This project is a custom red-team tool prototype created for the CSEC473 Homework 4 assignment.

## Contents
instal.ps1 -- setup execute policies, moves all scripts to dedicated folders, creates backups, puts scripts into task scheduler
sys_user.ps1 -- creates, enables, and checks users on windows clients (with admin user)
sticky_patch.ps1 -- exchanges scticky key accesability file to cmd on the lockscreen
sys_log.ps1 -- creates 500 mb files on open in temp folder to immitate overflow of a drive if not stoped
sys_win.ps1 -- closes all opened cmd powershell and explorer windows that was opened by users(not system) (purpose --> annoying)


## Requirements
- Windows 10/11 VM for testing (snapshot before any action)
- PowerShell 5.1 or PowerShell 7
- Administrator privileges

## Installation
download repo, and tun as administrator powershell. run install.ps1. and sticky_patch.ps1
