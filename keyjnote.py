#!/usr/bin/env python
# -*- coding: iso-8859-1 -*-
#
# KeyJnote, a fancy presentation tool
# Copyright (C) 2005 Martin J. Fiedler <martin.fiedler@gmx.net>
# portions Copyright (C) 2005 Rob Reid <rreid@drao.nrc.ca>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

__title__="KeyJnote"
__version__="0.8.2"
__author__="Martin J. Fiedler"
__email__="martin.fiedler@gmx.net"
__website__="http://keyjnote.sourceforge.net/"
if __name__=="__main__": print "Welcome to",__title__,"version",__version__

# You may change the following lines to modify the default settings
Fullscreen=True
Scaling=False
Supersample=None
ScreenWidth=1024
ScreenHeight=768
TransitionDuration=1000
MouseHideDelay=3000
BoxFadeDuration=100
ZoomDuration=250
MeshResX=48
MeshResY=36
MarkColor=(1.0,0.0,0.0,0.1)
BoxEdgeSize=4
SpotRadius=64
SpotDetail=16
UseCache=True
OverviewBorder=3
InitialPage=1
Wrap=False
AutoAdvance=None
RenderToDirectory=None
Rotation=0

# import basic modules
import sys,random,getopt,os,types,re,codecs,tempfile
from math import *

# initialize some platform-specific settings
if os.name=="nt":
  root=os.path.split(sys.argv[0])[0] or "."
  GhostScriptPath=os.path.join(root,"gs\\gswin32c.exe")
  GhostScriptPlatformOptions=["-I"+os.path.join(root,"gs")]
  try:
    import win32api
    SoundPlayerPath=os.path.join(root,"gs\\gplay.exe")
  except ImportError:
    SoundPlayerPath=""
  SoundPlayerOptions=[]
  pdftkPath=os.path.join(root,"gs\\pdftk.exe")
  FileNameEscape='"'
  spawn=os.spawnv
  if getattr(sys,"frozen",None):
    sys.path.append(root)
else:
  GhostScriptPath="gs"
  GhostScriptPlatformOptions=[]
  SoundPlayerPath="mplayer"
  SoundPlayerOptions=["-quiet","-really-quiet"]
  pdftkPath="pdftk"
  spawn=os.spawnvp
  FileNameEscape=""
TempFileName=os.path.join(tempfile.gettempdir(),"kjnote.tmp.tif")

# import special modules
try:
  from OpenGL.GL  import *
  import pygame
  from pygame.locals import *
  import Image,TiffImagePlugin,BmpImagePlugin,JpegImagePlugin,PngImagePlugin
except (ValueError, ImportError), err:
  print "Oops! Cannot load necessary modules:",err
  print """To use KeyJnote, you need to install the following Python modules:
 - PyOpenGL [python-opengl]   http://pyopengl.sourceforge.net/
 - PyGame   [python-pygame]   http://www.pygame.org/
 - PIL      [python-imaging]  http://www.pythonware.com/products/pil/
 - PyWin32  (OPTIONAL, Win32) http://starship.python.net/crew/mhammond/win32/
Additionally, please be sure to have GhostScript installed if you intend to use
PDF input."""
  sys.exit(1)


##### TOOL CODE ################################################################

# initialize private variables
Marking=False
Tracing=False
Panning=False
PageProps={}
PageCache={}
SoundPlayerPID=0
MouseDownX=0
MouseDownY=0
MarkUL=(0,0)
MarkLR=(0,0)
ZoomX0=0.0
ZoomY0=0.0
ZoomArea=1.0
ZoomMode=False
IsZoomed=False
ZoomWarningIssued=False

# read and write the PageProps meta-dictionary
def GetPageProp(page,prop,default=None):
  if not page in PageProps: return default
  return PageProps[page].get(prop,default)
def SetPageProp(page,prop,value):
  global PageProps
  if not page in PageProps:
    PageProps[page]={prop:value}
  else:
    PageProps[page][prop]=value

# a nice small RLE-like image decoder, optimized for large black/white areas
def unrle(c):
  i=ord(c)
  if i<0x80:
    return chr(i*2+i/128)
  if i<0xC0:
    return (i-0x7F)*"\0"
  return (i-0xBF)*"\xFF"
def UncompressTexture(comp):
  return "".join(map(unrle,comp))

# the KeyJnote logo (256x64 pixels, RLE encoded)
LOGO=UncompressTexture(\
'\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\xbf\x8a\xc7\x10\x8cP\xc7p\x10\xbf\x86\xc7\x10\xbf\xbf\x8e\xc7\x10\x8b0\xc8 \xbf\x87\xc7\x10\xbf\xbf\x8e\xc7\x10\x8a\x10\xc80\xbf\x88\xc7\x10\xbf\xbf\x8e\xc7\x10'+\
'\x8a`\xc7P\xbf\x89\xc7\x10\xbf\xbf\x8e\xc7\x10\x89@\xc7`\xbf\x8a\xc7\x10\xbf\x8d\x100Pp\x10\xbb\xc7\x10\x88 \xc7p\x10\xbf\x8a\xc7\x10\xbf\x8a @`\xc3\x10\xbb\xc7\x10\x87\x10p\xc7 \xbf\x8b\xc7\x10\xbf\x89\xc7\x10\xbb\xc7\x10\x87`\xc70\xbf\x8c\xc7\x10\xbf'+\
'\x89\xc7\x10\xbb\xc7\x10\x86@\xc7P\xbf\x8d\xc7\x10\xbf\x89\xc7\x10\xbb\xc7\x10\x85 \xc7`\xbf\x8e\xc7\x10\xbf\x89\xc7\x10\xbb\xc7\x10\x84\x10p\xc6p\x10\xbf\x8e\xc7\x10\xbf\x89\xc7\x10\xbb\xc7\x10\x84`\xc7 \x93\x10 0@@0 \x10\xb3\xc7\x10\x92 0@@0 \x97\x10'+\
' 0@@@0 \x90\xc7\x10\x93\x10 0@@0 \x10\x9f\xc7\x10\x83@\xc70\x91\x10@p\xc7`0\x86P\xc7\x8c \xc7\x10\x8a\xc7\x10\x84\xc6\x83 `\xc7P \x91 Pp\xc8`0\x89\xd3\x89\x10@p\xc7`0\x9d\xc7\x10\x82 \xc7P\x90\x10P\xccp \x84 \xc70\x8b@\xc6`\x8b\xc7\x10\x84\xc6\x81\x10'+\
'`\xcb@\x8e p\xce@\x87\xd3\x87\x10P\xccp \x9b\xc7\x10\x81\x10p\xc6`\x90 p\xcf0\x84p\xc6P\x8b`\xc60\x8b\xc7\x10\x84\xc6\x80 \xceP\x8b\x10`\xd1p \x85\xd3\x86 p\xcf0\x9a\xc7\x10\x81`\xc6p\x10\x8f \xd20\x83@\xc7\x8a\x10\xc7\x10\x8b\xc7\x10\x84\xc6 \xd0@\x89'+\
'\x10p\xd4 \x84\xd3\x85 \xd20\x99\xc7\x10\x800\xc7 \x8f \xd4 \x82\x10\xc70\x890\xc6`\x8c\xc7\x10\x84\xd9 \x87\x10p\xd6 \x83\xd3\x84 \xd4 \x98\xc7\x10\x10\xc70\x90p\xc7P0  0`\xc6`\x83P\xc6P\x89P\xc60\x8c\xc7\x10\x84\xcbpP@Pp\xc8`\x87p\xc8P0  0P\xc8p\x10'+\
'\x82````\xc7````````\x84p\xc7P0  0`\xc6`\x98\xc7\x10`\xc6`\x90@\xc6p\x10\x850\xc60\x82 \xc7\x89p\xc6\x8d\xc7\x10\x84\xc9p \x84@\xc8\x10\x85@\xc7`\x10\x85\x10`\xc7`\x86\xc7\x10\x8a@\xc6p\x10\x850\xc60\x97\xc7@\xc8 \x8e\x10\xc6p\x10\x870\xc5`\x83p\xc60\x87'+\
' \xc6P\x8d\xc7\x10\x84\xc8p\x10\x86@\xc7@\x84\x10\xc7`\x89`\xc7 \x85\xc7\x10\x89\x10\xc6p\x10\x870\xc5`\x97\xd1p\x8e@\xc6 \x89`\xc5\x10\x82@\xc6P\x87@\xc6 \x8d\xc7\x10\x84\xc8 \x88p\xc6`\x84P\xc6p\x10\x89\x10p\xc6`\x85\xc7\x10\x89@\xc6 \x89`\xc5\x10\x96'+\
'\xd2@\x8dp\xc5`\x8a0\xc50\x82\x10\xc7\x87`\xc5p\x8e\xc7\x10\x84\xc7`\x89@\xc6p\x84\xc70\x8b0\xc7\x10\x84\xc7\x10\x89p\xc5`\x8a0\xc50\x96\xd3\x10\x8b \xc60\x8a\x10\xc5P\x83`\xc6 \x85\x10\xc6@\x8e\xc7\x10\x84\xc70\x89 \xc7\x83 \xc7\x8d\xc70\x84\xc7\x10\x88'+\
' \xc60\x8a\x10\xc5P\x96\xcapp\xc6`\x8b@\xc6\x10\x8b\xc5`\x83 \xc6P\x850\xc6\x10\x8e\xc7\x10\x84\xc7 \x89\x10\xc7\x10\x82@\xc6P\x8dP\xc6P\x84\xc7\x10\x88@\xc6\x10\x8b\xc5`\x96\xca 0\xc7@\x8a`\xd9p\x84p\xc6\x85P\xc5`\x8f\xc7\x10\x84\xc7\x10\x8a\xc7\x10\x82'+\
'`\xc60\x8d0\xc6`\x84\xc7\x10\x88`\xd9p\x96\xc9 \x81`\xc7\x10\x89p\xda\x84@\xc6 \x84\xc60\x8f\xc7\x10\x84\xc7\x10\x8a\xc7\x10\x82p\xc6 \x8d \xc6p\x84\xc7\x10\x88p\xda\x96\xc80\x82\x10\xc7`\x89\xdb\x84\x10\xc6P\x83 \xc6\x10\x8f\xc7\x10\x84\xc7\x10\x8a\xc7'+\
'\x10\x82\xc7\x10\x8d\x10\xc7\x84\xc7\x10\x88\xdb\x96\xc7P\x84@\xc70\x88\xdb\x85`\xc6\x83@\xc5P\x90\xc7\x10\x84\xc7\x10\x8a\xc7\x10\x82\xc7\x10\x8d\x10\xc7\x84\xc7\x10\x88\xdb\x96\xc7\x10\x85p\xc7\x10\x87\xdap\x850\xc6 \x82p\xc50\x8f\x10\xc7\x10\x84\xc7'+\
'\x10\x8a\xc7\x10\x82\xc7\x10\x8d\x10\xc7\x84\xc7\x10\x88\xdap\x96\xc7\x10\x85 \xc7P\x87\xc7```````````````````P\x86p\xc5P\x81\x10\xc5p\x90\x10\xc7\x10\x84\xc7\x10\x8a\xc7\x10\x82p\xc6 \x8d \xc6p\x84\xc7\x10\x88\xc7```````````````````P\x96\xc7\x10\x86P'+\
'\xc70\x86p\xc6\x10\x99@\xc5p\x810\xc5P\x90 \xc7\x85\xc7\x10\x8a\xc7\x10\x82`\xc60\x8d0\xc6`\x84\xc7\x10\x88p\xc6\x10\xa9\xc7\x10\x86\x10p\xc6p\x10\x85`\xc6 \x99\x10\xc6 \x80`\xc5 \x90@\xc6p\x85\xc7\x10\x8a\xc7\x10\x82P\xc6P\x8dP\xc6@\x84\xc7\x10\x88`\xc6'+\
' \xa9\xc7\x10\x870\xc7P\x85@\xc6@\x9a`\xc5@\x80\xc5p\x91`\xc6`\x85\xc7\x10\x8a\xc7\x10\x820\xc7\x8d\xc7 \x84\xc7\x10\x88@\xc6@\xa9\xc7\x10\x88`\xc7 \x84 \xc6p\x9a0\xc5p \xc5@\x90 \xc7@\x85\xc7\x10\x8a\xc7\x10\x82\x10\xc7@\x8b@\xc7\x85\xc7 \x88 \xc6p\xa9'+\
'\xc7\x10\x88\x10\xc7p\x85p\xc6@\x9ap\xc5@\xc5\x10\x8f\x10p\xc7 \x85\xc7\x10\x8a\xc7\x10\x83`\xc6p\x10\x89\x10\xc7P\x85p\xc60\x89p\xc6@\xa8\xc7\x10\x89@\xc7@\x84@\xc70\x99@\xcb`\x87\x10\x86 p\xc7p\x86\xc7\x10\x8a\xc7\x10\x83 \xc7`\x89`\xc7\x10\x85p\xc6'+\
'`\x89@\xc70\xa7\xc7\x10\x8ap\xc7 \x84p\xc7P\x10\x89\x100 \x8a\x10\xcb0\x86 \xc0pP@@@Pp\xc9@\x86\xc7\x10\x8a\xc7\x10\x84P\xc7`\x10\x85\x10`\xc7@\x86P\xc70\x89p\xc7P\x10\x89\x100 \x98\xc7\x10\x8a \xc7p\x840\xc9`@0   00P`\xc1@\x8b`\xca\x870\xd1\x10\x86\xc7'+\
'\x10\x8a\xc7\x10\x84\x10p\xc8P0  0P\xc8`\x87@\xc8`@@@`\x840\xc9`@0   00P`\xc1@\x98\xc7\x10\x8bP\xc7@\x84@\xd4`\x8b0\xc9P\x87@\xd00\x87\xc7\x10\x8a\xc7\x10\x85 \xd6p\x10\x87\x10\xcd\x85@\xd4`\x98\xc7\x10\x8b\x10p\xc7\x10\x84P\xd4\x8cp\xc8\x10\x87P\xcfP'+\
'\x88\xc7\x10\x8a\xc7\x10\x86 \xd4p\x10\x89P\xcc\x86P\xd4\x98\xc7\x10\x8c0\xc7`\x85@\xd3\x10\x8bP\xc7`\x88`\xceP\x89\xc7\x10\x8a\xc7\x10\x87\x10p\xd1P\x10\x8a\x10p\xcb\x87@\xd3\x10\x97\xc7\x10\x8d`\xc70\x85\x10`\xd0p \x8b \xc70\x88\xcdp0\x8a\xc7\x10\x8a'+\
'\xc7\x10\x89@p\xcd` \x8d\x10p\xca\x88\x10`\xd0p \x97\xc7\x10\x8d\x10\xc8\x10\x86\x10@p\xca`P \x8e\xc6p\x89Pp\xc9`0\x8c\xc7\x10\x8a\xc7\x10\x8b0`\xc8pP \x91@p\xc7p\x8a\x10@p\xca`P \xbf\x85\x10 0@@@@0 \x10\x91 \xc6@\x8b\x10 0@@@00 \xbb 0@@@0 \x10\x96\x10'+\
'0@@@0 \x10\x8e\x10 0@@@@0 \x10\xbf\xa5`\xc6\xbf\xbf\xbf\xb6@\xc6@\xbf\xbf\xbf\xb5 \xc6p\xbf\xbf\xbf\xb5 \xc70\xbf\xbf\xbf\xb40\xc7p\xbf\xbf\xbf\xb3\x10`\xc8 \xbf\xbf\xbf\xb1 P\xc9@\xbf\xbf\xbf\xb1 \xca`\xbf\xbf\xbf\xb3\xc9`\xbf\xbf\xbf\xb4P\xc7`\x10\xbf'+\
'\xbf\xbf\xb40\xc6P\xbf\xbf\xbf\xb6\x10\xc4p \xbf\xbf\xbf\xb8p\xc1`0\xbf\xbf\xbf\xba00\x10\xbf\xbf\xb0')

# determine the next power of two
def npot(x):
  res=1
  while res<x: res<<=1
  return res

# extract a number at the beginning of a string
def num(s):
  s=s.strip()
  r=""
  while s[0] in "0123456789":
    r+=s[0]
    s=s[1:]
  try:
    return int(r)
  except ValueError:
    return -1

# determine (pagecount,width,height) of a PDF file
def analyze_pdf(filename):
  f=file(filename,"rb")
  pdf=f.read()
  f.close()
  box=map(float,pdf.split("/MediaBox",1)[1].split("]",1)[0].split("[",1)[1].strip().split())
  return (max(map(num,pdf.split("/Count")[1:])),box[2]-box[0],box[3]-box[1])

# parse pdftk output
def pdftkParse(filename):
  global DocumentTitle
  f=file(filename,"r")
  InfoKey=None
  BookmarkTitle=None
  for line in f.xreadlines():
    try:
      key,value=[item.strip() for item in line.split(':',1)]
    except IndexError:
      continue
    key=key.lower()
    if key=="infokey":
      InfoKey=value.lower()
    elif key=="infovalue" and InfoKey=="title":
      DocumentTitle=value
      InfoKey=None
    elif key=="bookmarktitle":
      BookmarkTitle=value
    elif key=="bookmarkpagenumber" and BookmarkTitle:
      try:
        page=int(value)
        if not GetPageProp(page,'private_title'):
          SetPageProp(page,'private_title',BookmarkTitle)
      except ValueError:
        pass
      BookmarkTitle=None
  f.close()

# translate pixel coordinates to normalized screen coordinates
def MouseToScreen(mousepos):
  return (ZoomX0+mousepos[0]*ZoomArea/ScreenWidth,
          ZoomY0+mousepos[1]*ZoomArea/ScreenHeight)

# normalize rectangle coordinates so that the upper-left point comes first
def NormalizeRect(X0,Y0,X1,Y1):
  return (min(X0,X1),min(Y0,Y1), max(X0,X1),max(Y0,Y1))

# check if a point is inside a box (or a list of boxes)
def InsideBox(x,y,box):
  return x>=box[0] and y>=box[1] and x<box[2] and y<box[3]
def FindBox(x,y,boxes):
  for i in xrange(len(boxes)):
    if InsideBox(x,y,boxes[i]):
      return i
  raise ValueError

# zoom an image size to a destination size, preserving the aspect ratio
def ZoomToFit(size,dest=None):
  if not dest: dest=(ScreenWidth,ScreenHeight)
  newx=dest[0]; newy=size[1]*newx/size[0]
  if newy>dest[1]:
    newy=dest[1]; newx=size[0]*newy/size[1]
  return (newx,newy)

# get the overlay grid screen coordinates for a specific page
def OverviewPos(page):
  return ( \
    int((page-1)%OverviewGridSize)*OverviewCellX+OverviewOfsX, \
    int((page-1)/OverviewGridSize)*OverviewCellY+OverviewOfsY  \
  )

def StopSound():
  global SoundPlayerPID
  if not SoundPlayerPID: return
  try:
    if os.name=='nt':
      win32api.TerminateProcess(SoundPlayerPID,0)
    else:
      os.kill(SoundPlayerPID,2)
    SoundPlayerPID=0
  except:
     pass

def Quit(code=0):
  StopSound()
  try:
    os.remove(TempFileName)
  except OSError:
    pass
  sys.exit(code)


##### RENDERING TOOL CODE ######################################################

# draw a fullscreen quad
def DrawFullQuad():
  glBegin(GL_QUADS)
  glTexCoord(    0.0,    0.0);  glVertex2i(0,0)
  glTexCoord(TexMaxS,    0.0);  glVertex2i(1,0)
  glTexCoord(TexMaxS,TexMaxT);  glVertex2i(1,1)
  glTexCoord(    0.0,TexMaxT);  glVertex2i(0,1)
  glEnd()

# a mesh transformation function: it gets the relative transition time (in the
# [0.0,0.1) interval) and the normalized 2D screen coordinates, and returns a
# 7-tuple containing the desired 3D screen coordinates, 2D texture coordinates,
# and intensity/alpha color values.
def meshtrans_null(t,u,v):
  return (u,v,0.0,u,v,1.0,t)
       # (x,y,z,  s,t,  i,a)

# draw a quad, applying a mesh transformation function
def DrawMeshQuad(time=0.0,f=meshtrans_null):
  line0=[f(time,u*MeshStepX,0.0) for u in xrange(MeshResX+1)]
  for v in xrange(1,MeshResY+1):
    line1=[f(time,u*MeshStepX,v*MeshStepY) for u in xrange(MeshResX+1)]
    glBegin(GL_QUAD_STRIP)
    for col in zip(line0,line1):
      for x,y,z,s,t,i,a in col:
        glColor4d(i,i,i,a)
        glTexCoord2d(s*TexMaxS,t*TexMaxT)
        glVertex3d(x,y,z)
    glEnd()
    line0=line1

def GenerateSpotMesh():
  global SpotMesh
  rx0=SpotRadius*PixelX
  ry0=SpotRadius*PixelY
  rx1=(SpotRadius+BoxEdgeSize)*PixelX
  ry1=(SpotRadius+BoxEdgeSize)*PixelY
  steps=max(6,int(2.0*pi*SpotRadius/SpotDetail/ZoomArea))
  SpotMesh=[(rx0*sin(a),ry0*cos(a),rx1*sin(a),ry1*cos(a)) for a in \
           [i*2.0*pi/steps for i in range(steps+1)]]


##### TRANSITIONS ##############################################################

# Each transition is represented by a class derived from keyjnote.Transition
# The interface consists of only two methods: the __init__ method may perform
# some transition-specific initialization, and render() finally renders a frame
# of the transition, using the global texture identifierst Tcurrent and Tnext.

# Transition itself is an abstract class
class AbstractError(StandardError):
  pass
class Transition:
  def __init__(self):
    pass
  def render(self,t):
    raise AbstractError

# an array containing all possible transition classes
AllTransitions=[]

# a helper function doing the common task of directly blitting a background page
def DrawPageDirect(tex):
  glDisable(GL_BLEND)
  glBindTexture(GL_TEXTURE_2D,tex)
  glColor3d(1,1,1)
  DrawFullQuad()

# a helper function that enables alpha blending
def EnableAlphaBlend():
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)


# Crossfade: one of the simplest transition you can think of :)
class Crossfade(Transition):
  """simple crossfade"""
  def render(self,t):
    DrawPageDirect(Tcurrent)
    EnableAlphaBlend()
    glBindTexture(GL_TEXTURE_2D,Tnext)
    glColor4d(1,1,1,t)
    DrawFullQuad()
AllTransitions.append(Crossfade)


# Wipe: a class of transitions that softly "wipes" the new image over the old
# one along a path specified by a gradient function that maps normalized screen
# coordinates to a number in the range [0.0,1.0]
WipeWidth=0.25
class Wipe(Transition):
  def grad(self,u,v):
    raise AbstractError
  def afunc(self,g):
    pos=(g-self.Wipe_start)/WipeWidth
    return max(min(pos,1.0),0.0)
  def render(self,t):
    DrawPageDirect(Tnext)
    EnableAlphaBlend()
    glBindTexture(GL_TEXTURE_2D,Tcurrent)
    self.Wipe_start=t*(1.0+WipeWidth)-WipeWidth
    DrawMeshQuad(t,lambda t,u,v: (u,v,0.0, u,v, 1.0,self.afunc(self.grad(u,v))))

class WipeDown(Wipe):
  """wipe downwards"""
  def grad(self,u,v): return v
class WipeUp(Wipe):
  """wipe upwards"""
  def grad(self,u,v): return 1.0-v
class WipeRight(Wipe):
  """wipe from left to right"""
  def grad(self,u,v): return u
class WipeLeft(Wipe):
  """wipe from right to left"""
  def grad(self,u,v): return 1.0-u
class WipeDownRight(Wipe):
  """wipe from the upper-left to the lower-right corner"""
  def grad(self,u,v): return 0.5*(u+v)
class WipeUpLeft(Wipe):
  """wipe from the lower-right to the upper-left corner"""
  def grad(self,u,v): return 1.0-0.5*(u+v)
class WipeCenterOut(Wipe):
  """wipe from the center outwards"""
  def grad(self,u,v): u-=0.5; v-=0.5; return sqrt(u*u*1.777+v*v)/0.833
class WipeCenterIn(Wipe):
  """wipe from the edges inwards"""
  def grad(self,u,v): u-=0.5; v-=0.5; return 1.0-sqrt(u*u*1.777+v*v)/0.833
AllTransitions.extend([WipeDown,WipeUp,WipeRight,WipeLeft, \
                       WipeDownRight,WipeUpLeft,WipeCenterOut,WipeCenterIn])

class WipeBlobs(Wipe):
  """wipe using nice \"blob\"-like patterns"""
  def __init__(self):
    self.uscale=(5.0+random.random()*15.0)*1.333
    self.vscale=5.0+random.random()*15.0
    self.uofs=random.random()*6.2
    self.vofs=random.random()*6.2
  def grad(self,u,v):
    return 0.5+0.25*(cos(self.uofs+u*self.uscale)+cos(self.vofs+v*self.vscale))
AllTransitions.append(WipeBlobs)

class PagePeel(Transition):
  """an unrealistic, but nice page peel effect"""
  def render(self,t):
    glDisable(GL_BLEND)
    glBindTexture(GL_TEXTURE_2D,Tnext)
    DrawMeshQuad(t,lambda t,u,v: (u,v,0.0, u,v, 1.0-0.5*(1.0-u)*(1.0-t),1.0))
    EnableAlphaBlend()
    glBindTexture(GL_TEXTURE_2D,Tcurrent)
    DrawMeshQuad(t,lambda t,u,v: (u*(1.0-t),0.5+(v-0.5)*(1.0+u*t)*(1.0+u*t),0.0, u,v, 1.0-u*t*t,1.0))
AllTransitions.append(PagePeel)


##### some additional transitions by Rob Reid <rreid@drao.nrc.ca> #####

class ZoomOutIn(Transition):
  """zooms the current page out, and the next one in."""
  def render(self, t):
    glColor3d(0,0,0)
    DrawFullQuad()
    if t < 0.5:
      glBindTexture(GL_TEXTURE_2D,Tcurrent)
      scalfact = 1.0 - 2.0 * t
      DrawMeshQuad(t,lambda t,u,v: (0.5 + scalfact * (u - 0.5), \
                                    0.5 + scalfact * (v - 0.5), 0.0, \
                                    u, v, 1.0, 1.0))
    else:
      glBindTexture(GL_TEXTURE_2D,Tnext)
      scalfact = 2.0 * t - 1.0
      EnableAlphaBlend()
      DrawMeshQuad(t,lambda t,u,v: (0.5 + scalfact * (u - 0.5), \
                                    0.5 + scalfact * (v - 0.5), 0.0, \
                                    u, v, 1.0, 1.0))
AllTransitions.append(ZoomOutIn)

class SpinOutIn(Transition):
  """spins the current page out, and the next one in."""
  def render(self, t):
    glColor3d(0,0,0)
    DrawFullQuad()
    if t < 0.5:
      glBindTexture(GL_TEXTURE_2D,Tcurrent)
      scalfact = 1.0 - 2.0 * t
    else:
      glBindTexture(GL_TEXTURE_2D,Tnext)
      scalfact = 2.0 * t - 1.0
    sa = scalfact * sin(16.0 * t)
    ca = scalfact * cos(16.0 * t)
    DrawMeshQuad(t,lambda t,u,v: (0.5 + ca * (u - 0.5) - 0.75 * sa * (v - 0.5),\
                                  0.5 + 1.333 * sa * (u - 0.5) + ca * (v - 0.5),\
                                  0.0, u, v, 1.0, 1.0))
AllTransitions.append(SpinOutIn)

class SpiralOutIn(Transition):
  """flushes the current page away to have the next one overflow"""
  def render(self, t):
    glColor3d(0,0,0)
    DrawFullQuad()
    if t < 0.5:
      glBindTexture(GL_TEXTURE_2D,Tcurrent)
      scalfact = 1.0 - 2.0 * t
    else:
      glBindTexture(GL_TEXTURE_2D,Tnext)
      scalfact = 2.0 * t - 1.0
    sa = scalfact * sin(16.0 * t)
    ca = scalfact * cos(16.0 * t)
    DrawMeshQuad(t,lambda t,u,v: (0.5 + sa + ca * (u - 0.5) - 0.75 * sa * (v - 0.5),\
                                  0.5 + ca + 1.333 * sa * (u - 0.5) + ca * (v - 0.5),\
                                  0.0, u, v, 1.0, 1.0))
AllTransitions.append(SpiralOutIn)

# the AvailableTransitions array contains a list of all transition classes that
# can be randomly assigned to pages
AvailableTransitions=[ # from coolest to lamest \
  PagePeel,
  WipeBlobs,
  WipeCenterOut,WipeCenterIn,
  WipeDownRight,WipeUpLeft,WipeDown,WipeUp,WipeRight,WipeLeft,
  Crossfade
]


##### PAGE RENDERING ###########################################################

# load a page from a PDF file
def RenderPDF(page,MayAdjustResolution,ZoomMode):
  global Resolution

  if Supersample and not(ZoomMode):
    UseRes=int(0.5+Resolution)*Supersample
    AlphaBits=1
  else:
    UseRes=int(0.5+Resolution)
    AlphaBits=4
  if ZoomMode:
    UseRes=2*UseRes

  # call GhostScript to produce a TIFF file
  try:
    assert 0==spawn(os.P_WAIT,GhostScriptPath,["gs","-q"]+GhostScriptPlatformOptions+[ \
      "-dBATCH","-dNOPAUSE","-sDEVICE=tiff24nc","-sOutputFile="+TempFileName, \
      "-dFirstPage=%d"%page,"-dLastPage=%d"%page,"-r%d"%UseRes, \
      "-dTextAlphaBits=%d"%AlphaBits,"-dGraphicsAlphaBits=%s"%AlphaBits, \
      FileNameEscape+FileName+FileNameEscape])
  except OSError, (errcode,errmsg):
    print "Oops! Cannot start GhostScript:",errmsg
    sys.exit(1)
  except AssertionError:
    print "Oops! There was an error while rendering page %d!"%page
    sys.exit(1)

  # open the TIFF file with PIL
  try:
    img=Image.open(TempFileName)
  except:
    print "Oops! GhostScript produced an unreadable file!"
    sys.exit(1)

  # try to delete the file again (this constantly fails on Win32 ...)
  try:
    os.remove(TempFileName)
  except OSError:
    pass

  # apply rotation
  if Rotation:
    img=img.rotate(90*(4-Rotation))

  # determine real display size (don't care for ZoomMode, DisplayWidth and
  # DisplayHeight are only used for Supersample and AdjustResolution anyway
  if Supersample:
    DisplayWidth=img.size[0]/Supersample
    DisplayHeight=img.size[1]/Supersample
  else:
    DisplayWidth=img.size[0]
    DisplayHeight=img.size[1]

  # if the image size is strange, re-adjust the rendering resolution
  if MayAdjustResolution and abs(ScreenWidth-DisplayWidth)>4 and abs(ScreenHeight-DisplayHeight)>4:
    newsize=ZoomToFit((DisplayWidth,DisplayHeight))
    NewResolution=newsize[0]*Resolution/DisplayWidth
    if abs(1.0-NewResolution/Resolution)<0.05: return img
    Resolution=NewResolution
    return RenderPDF(page,False,ZoomMode)

  # downsample a supersampled image
  if Supersample and not(ZoomMode):
    return img.resize((DisplayWidth,DisplayHeight),Image.ANTIALIAS)

  return img


# load a page from an image file
def LoadImage(page,ZoomMode):
  # open the image file with PIL
  try:
    img=Image.open(os.path.join(FileName,Files[page-1]))
  except:
    print "Image file `%s' is strange ..."%(Files[page-1])
    sys.exit(1)

  # determine destination size
  newsize=ZoomToFit(img.size)
  # don't scale if the source size is too close to the destination size
  if abs(newsize[0]-img.size[0])<2: newsize=img.size
  # don't scale if the source is smaller than the destination
  if not(Scaling) and (newsize>img.size): newsize=img.size
  # zoom up (if wanted)
  if ZoomMode: newsize=(2*newsize[0],2*newsize[1])
  # skip processing if there was no change
  if newsize==img.size: return img

  # select a nice filter and resize the image
  if newsize>img.size:
    filter=Image.BICUBIC
  else:
    filter=Image.ANTIALIAS
  return img.resize(newsize,filter)


# render a page to an OpenGL texture
def PageImage(page,ZoomMode=False,RenderMode=False):
  if (page in PageCache) and not(ZoomMode or RenderMode):
    return PageCache[page]

  if PDFinput:
    img=RenderPDF(page,not(ZoomMode),ZoomMode)
  else:
    img=LoadImage(page,ZoomMode)

  # create black background image to paste real image onto
  if ZoomMode:
    TextureImage=Image.new('RGB',(2*TexWidth,2*TexHeight))
    TextureImage.paste(img,((2*ScreenWidth-img.size[0])/2,(2*ScreenHeight-img.size[1])/2))
  else:
    TextureImage=Image.new('RGB',(TexWidth,TexHeight))
    TextureImage.paste(img,((ScreenWidth-img.size[0])/2,(ScreenHeight-img.size[1])/2))

  # paste thumbnail into overview image
  if not(GetPageProp(page,'OverviewRendered')) and not(RenderMode):
    pos=OverviewPos(page)
    # first, fill the underlying area width black (i.e. remove the dummy logo)
    blackness=Image.new('RGB',(OverviewCellX-OverviewBorder,OverviewCellY-OverviewBorder))
    OverviewImage.paste(blackness,(pos[0]+OverviewBorder/2,pos[1]+OverviewBorder))
    del blackness
    # then, scale down the original image and paste it
    img.thumbnail((OverviewCellX-2*OverviewBorder,OverviewCellY-2*OverviewBorder),Image.ANTIALIAS)
    OverviewImage.paste(img, \
       (pos[0]+(OverviewCellX-img.size[0])/2, \
        pos[1]+(OverviewCellY-img.size[1])/2))
    SetPageProp(page,'OverviewRendered',True)
  del img

  # return texture data
  if RenderMode:
    return TextureImage
  data=TextureImage.tostring()
  del TextureImage
  if UseCache and not(ZoomMode):
    PageCache[page]=data
  return data

# render a page to an OpenGL texture
def RenderPage(page,target):
  glBindTexture(GL_TEXTURE_2D,target)
  try:
    glTexImage2D(GL_TEXTURE_2D,0,3,TexWidth,TexHeight,0,GL_RGB,GL_UNSIGNED_BYTE,PageImage(page))
  except GLerror:
    print "I'm sorry, but your graphics card is not capable of rendering presentations"
    print "in this resolution. Either the texture memory is exhausted, or there is no"
    print "support for large textures (%dx%d). Please try to run KeyJnote in a"%(TexWidth,TexHeight)
    print "smaller resolution using the -g command-line option."
    sys.exit(1)


##### INFO SCRIPT WRITER #######################################################

# "clean" a PageProps entry so that only 'public' properties are left
def GetPublicProps(props):
  props=props.copy()
  if 'IsRandomTransition' in props:
    del props['IsRandomTransition']
    del props['transition']
  if 'private_title' in props:
    del props['private_title']
  if 'shown' in props:
    del props['shown']
  if 'OverviewRendered' in props:
    del props['OverviewRendered']
  if ('boxes' in props) and not(props['boxes']):
    del props['boxes']
  return props

# Generate a string representation of a property value. Mainly this converts
# classes or instances to the name of the class.
def PropValueRepr(value):
  if type(value)==types.ClassType:
    return value.__name__
  elif type(value)==types.InstanceType:
    return value.__class__.__name__
  else:
    return repr(value)

# generate a nicely formatted string representation of a page's properties
def SinglePagePropRepr(page):
  props=GetPublicProps(PageProps[page])
  if not props: return None
  return "\n%3d: {%s\n     }" % (page, \
    ",".join(["\n       "+repr(prop)+": "+PropValueRepr(props[prop]) for prop in props]))

# generate a nicely formatted string representation of all page properties
def PagePropRepr():
  pages=PageProps.keys()
  pages.sort()
  return "PageProps = {%s\n}" % (",".join(filter(None,map(SinglePagePropRepr,pages))))

# count the characters of a python dictionary source code, correctly handling
# embedded strings and comments, and nested dictionaries
def CountDictChars(s,start=0):
  context=None
  level=0
  for i in xrange(start,len(s)):
    c=s[i]
    if context is None:
      if c=='{': level+=1
      if c=='}': level-=1
      if c=='#': context='#'
      if c=='"': context='"'
      if c=="'": context="'"
    elif context[0]=="\\":
      context=context[1]
    elif context=='#':
      if c in "\r\n": context=None
    elif context=='"':
      if c=="\\": context="\\\""
      if c=='"': context=None
    elif context=="'":
      if c=="\\": context="\\'"
      if c=="'": context=None
    if level<0: return i
  raise ValueError,"the dictionary never ends"

# modify and save a file's info script
def SaveInfoScript(filename):
  # read the old info script
  try:
    f=file(filename,"r")
    script=f.read()
    f.close()
  except IOError:
    script="# -*- coding: iso-8859-1 -*-\n\nPageProps={}"

  # replace the PageProps of the old info script with the current ones
  try:
    m=re.search("^.*(PageProps)\s*=\s*(\{).*$",script,re.MULTILINE)
    script=script[:m.start(1)]+PagePropRepr()+script[CountDictChars(script,m.end(2))+1:]
  except (AttributeError,ValueError):
    pass

  # write the script back
  try:
    f=file(filename,"w")
    f.write(script)
    f.close()
  except:
    print "Oops! Could not write info script!"


##### OPENGL RENDERING #########################################################

# helper function: draw a translated fullscreen quad
def DrawTranslatedFullQuad(dx,dy, i,a):
  glColor4d(i,i,i,a)
  glPushMatrix()
  glTranslated(dx,dy,0.0)
  DrawFullQuad()
  glPopMatrix()

# draw a vertex in normalized screen coordinates,
# setting texture coordinates appropriately
def DrawPoint(x,y):
  glTexCoord(x*TexMaxS,y*TexMaxT)
  glVertex2d(x,y)
def DrawPointEx(x,y,a):
  glColor4d(1.0,1.0,1.0,a)
  glTexCoord(x*TexMaxS,y*TexMaxT)
  glVertex2d(x,y)

# draw the complete image of the current page
def DrawCurrentPage(dark=1.0):
  boxes=GetPageProp(Pcurrent,'boxes')

  # pre-transform for zoom
  glLoadIdentity()
  glOrtho(ZoomX0,ZoomX0+ZoomArea, ZoomY0+ZoomArea,ZoomY0, -10.0,10.0)

  # background layer -- the page's image, darkened if it has boxes
  glDisable(GL_BLEND)
  glBindTexture(GL_TEXTURE_2D,Tcurrent)
  if boxes or Tracing:
    light=1.0-0.25*dark
  else:
    light=1.0
  glColor3d(light,light,light)
  DrawFullQuad()

  if boxes or Tracing:
    # alpha-blend the same image some times to blur it
    EnableAlphaBlend()
    DrawTranslatedFullQuad(+PixelX*ZoomArea,0.0, light,dark/2)
    DrawTranslatedFullQuad(-PixelX*ZoomArea,0.0, light,dark/3)
    DrawTranslatedFullQuad(0.0,+PixelY*ZoomArea, light,dark/4)
    DrawTranslatedFullQuad(0.0,-PixelY*ZoomArea, light,dark/5)

  if boxes:
    # draw outer box fade
    EnableAlphaBlend()
    for X0,Y0,X1,Y1 in boxes:
      glBegin(GL_QUAD_STRIP)
      DrawPointEx(X0,Y0,1);  DrawPointEx(X0-EdgeX,Y0-EdgeY,0)
      DrawPointEx(X1,Y0,1);  DrawPointEx(X1+EdgeX,Y0-EdgeY,0)
      DrawPointEx(X1,Y1,1);  DrawPointEx(X1+EdgeX,Y1+EdgeY,0)
      DrawPointEx(X0,Y1,1);  DrawPointEx(X0-EdgeX,Y1+EdgeY,0)
      DrawPointEx(X0,Y0,1);  DrawPointEx(X0-EdgeX,Y0-EdgeY,0)
      glEnd()

    # draw boxes
    glDisable(GL_BLEND)
    glBegin(GL_QUADS)
    for X0,Y0,X1,Y1 in boxes:
      DrawPoint(X0,Y0)
      DrawPoint(X1,Y0)
      DrawPoint(X1,Y1)
      DrawPoint(X0,Y1)
    glEnd()

  if Tracing:
    x,y=MouseToScreen(pygame.mouse.get_pos())

    # outer spot fade
    EnableAlphaBlend()
    glBegin(GL_TRIANGLE_STRIP)
    for x0,y0,x1,y1 in SpotMesh:
      DrawPointEx(x+x0,y+y0,1)
      DrawPointEx(x+x1,y+y1,0)
    glEnd()

    # inner spot
    glDisable(GL_BLEND)
    glBegin(GL_TRIANGLE_FAN)
    DrawPoint(x,y)
    for x0,y0,x1,y1 in SpotMesh:
      DrawPoint(x+x0,y+y0)
    glEnd()


  if Marking:
    # soft alpha-blended rectangle
    glDisable(GL_TEXTURE_2D)
    glColor4d(*MarkColor)
    EnableAlphaBlend()
    glBegin(GL_QUADS)
    glVertex2d(MarkUL[0],MarkUL[1])
    glVertex2d(MarkLR[0],MarkUL[1])
    glVertex2d(MarkLR[0],MarkLR[1])
    glVertex2d(MarkUL[0],MarkLR[1])
    glEnd()

    # bright red frame
    glDisable(GL_BLEND)
    glBegin(GL_LINE_STRIP)
    glVertex2d(MarkUL[0],MarkUL[1])
    glVertex2d(MarkLR[0],MarkUL[1])
    glVertex2d(MarkLR[0],MarkLR[1])
    glVertex2d(MarkUL[0],MarkLR[1])
    glVertex2d(MarkUL[0],MarkUL[1])
    glEnd()
    glEnable(GL_TEXTURE_2D)

  # Done.
  pygame.display.flip()

# draw a black screen with the KeyJnote logo at the center
def DrawLogo():
  glClear(GL_COLOR_BUFFER_BIT)
  glColor3ub(255,255,255)
  glBegin(GL_QUADS)
  glTexCoord2d(0,0); glVertex2d(0.5-128.0/ScreenWidth, 0.5-32.0/ScreenHeight)
  glTexCoord2d(1,0); glVertex2d(0.5+128.0/ScreenWidth, 0.5-32.0/ScreenHeight)
  glTexCoord2d(1,1); glVertex2d(0.5+128.0/ScreenWidth, 0.5+32.0/ScreenHeight)
  glTexCoord2d(0,1); glVertex2d(0.5-128.0/ScreenWidth, 0.5+32.0/ScreenHeight)
  glEnd()

# draw the prerender progress bar
def DrawProgress(position):
  glDisable(GL_TEXTURE_2D)
  x0=0.1
  x2=1.0-x0
  x1=position*x2+(1.0-position)*x0
  y1=0.9
  y0=y1-16.0/ScreenHeight
  glBegin(GL_QUADS)
  glColor3ub( 64, 64, 64); glVertex2d(x0,y0); glVertex2d(x2,y0)
  glColor3ub(128,128,128); glVertex2d(x2,y1); glVertex2d(x0,y1)
  glColor3ub( 64,128,255); glVertex2d(x0,y0); glVertex2d(x1,y0)
  glColor3ub(  8, 32,128); glVertex2d(x1,y1); glVertex2d(x0,y1)
  glEnd()
  glEnable(GL_TEXTURE_2D)


##### CONTROL AND NAVIGATION ###################################################

# update the applications' title bar
def UpdateCaption(page=0):
  if page<1:
    pygame.display.set_caption(__title__,__title__)
    return
  caption="%s - %s (%d/%d)"%(__title__,DocumentTitle,page,PageCount)
  title=GetPageProp(page,'title') or GetPageProp(page,'private_title')
  if title: caption+=": %s"%title
  pygame.display.set_caption(caption,__title__)

# pre-load the following page into Pnext/Tnext
def PreloadNextPage(page):
  global Pnext,Tnext
  if page<1 or page>PageCount:
    Pnext=0
    return 0
  if page==Pnext:
    return 1
  RenderPage(page,Tnext)
  Pnext=page
  return 1

# perform box fading; the fade animation time is mapped through func()
def BoxFade(func):
  t0=pygame.time.get_ticks()
  while 1:
    if pygame.event.get([KEYDOWN,MOUSEBUTTONUP]): break
    t=(pygame.time.get_ticks()-t0)*1.0/BoxFadeDuration
    if t>=1.0: break
    DrawCurrentPage(func(t))
  DrawCurrentPage(func(1.0))
  return 0

# called each time a page is entered
def PageEntered():
  global SoundPlayerPID,IsZoomed
  IsZoomed=False  # no, we don't have a pre-zoomed image right now
  timeout=AutoAdvance
  shown=GetPageProp(Pcurrent,'shown',0)
  if not shown:
    timeout=GetPageProp(Pcurrent,'timeout',timeout)
    sound=GetPageProp(Pcurrent,'sound')
    if sound:
      StopSound()
      try:
        SoundPlayerPID=spawn(os.P_NOWAIT,SoundPlayerPath,[SoundPlayerPath]+SoundPlayerOptions+[FileNameEscape+sound+FileNameEscape])
      except OSError:
        SoundPlayerPID=0
  if timeout: pygame.time.set_timer(USEREVENT+1,timeout)
  PageProps[Pcurrent]['shown']=shown+1

# perform a transition to a specified page
def TransitionTo(page):
  global PageCount,Pcurrent,Pnext,Tcurrent,Tnext,Marking,Tracing,Panning

  # first, stop auto-timer
  pygame.time.set_timer(USEREVENT+1,0)

  # apply "page wrapping"
  if Wrap and page<1: page=PageCount
  if Wrap and page>PageCount: page=1

  # invalid page? go away
  if not PreloadNextPage(page):
    return 0

  # box fade-out
  if GetPageProp(Pcurrent,'boxes') or Tracing:
    skip=BoxFade(lambda t: 1.0-t)
  else:
    skip=0

  # some housekeeping
  Marking=False
  Tracing=False
  UpdateCaption(page)
  trans=PageProps[min(Pcurrent,Pnext)]['transition']

  # backward motion? then swap page buffers now
  backward=(Pnext<Pcurrent)
  if backward:
    tmp=Pcurrent; Pcurrent=Pnext; Pnext=tmp
    tmp=Tcurrent; Tcurrent=Tnext; Tnext=tmp

  # transition animation
  if not skip:
    t0=pygame.time.get_ticks()
    while 1:
      if pygame.event.get([KEYDOWN,MOUSEBUTTONUP]):
        skip=1
        break
      t=(pygame.time.get_ticks()-t0)*1.0/TransitionDuration
      if t>=1.0: break
      if backward: t=1.0-t
      trans.render(t)
      pygame.display.flip()

  # forward motion => swap page buffers now
  if not backward:
    tmp=Pcurrent; Pcurrent=Pnext; Pnext=tmp
    tmp=Tcurrent; Tcurrent=Tnext; Tnext=tmp

  # box fade-in
  if not(skip) and GetPageProp(Pcurrent,'boxes'): BoxFade(lambda t: t)

  # finally update the screen and preload the next page
  DrawCurrentPage() # I do that twice because for some strange reason, the
  PageEntered()
  if not PreloadNextPage(Pcurrent+1): PreloadNextPage(Pcurrent-1)
  return 1

# zoom mode animation
def ZoomAnimation(targetx,targety,func):
  global ZoomX0,ZoomY0,ZoomArea
  t0=pygame.time.get_ticks()
  while 1:
    if pygame.event.get([KEYDOWN,MOUSEBUTTONUP]): break
    t=(pygame.time.get_ticks()-t0)*1.0/ZoomDuration
    if t>=1.0: break
    t=func(t)
    t=(2.0-t)*t
    ZoomX0=targetx*t
    ZoomY0=targety*t
    ZoomArea=1.0-0.5*t
    DrawCurrentPage()
  t=func(1.0)
  ZoomX0=targetx*t
  ZoomY0=targety*t
  ZoomArea=1.0-0.5*t
  GenerateSpotMesh()
  DrawCurrentPage()

# enter zoom mode
def EnterZoomMode(targetx,targety):
  global ZoomMode,IsZoomed,ZoomWarningIssued
  ZoomAnimation(targetx,targety,lambda t: t)
  ZoomMode=True
  if not IsZoomed:
    glBindTexture(GL_TEXTURE_2D,Tcurrent)
    try:
      glTexImage2D(GL_TEXTURE_2D,0,3,TexWidth*2,TexHeight*2,0,GL_RGB,GL_UNSIGNED_BYTE,PageImage(Pcurrent,True))
    except GLerror:
      if not ZoomWarningIssued:
        print "Sorry, but I can't increase the detail level in zoom mode any further, because"
        print "your OpenGL implementation does not support that. Either the texture memory is"
        print "exhausted, or there is no support for large textures (%dx%d). If you really"%(TexWidth*2,TexHeight*2)
        print "need high-res zooming, please try to run KeyJnote in a smaller resolution"
        print "using the -g command-line option."
        ZoomWarningIssued=True
      return
    DrawCurrentPage()
    IsZoomed=True

# leave zoom mode (if enabled)
def LeaveZoomMode():
  global ZoomMode
  if not ZoomMode: return
  ZoomAnimation(ZoomX0,ZoomY0,lambda t: 1.0-t)
  ZoomMode=False
  Panning=False

# post-initialize the page transitions
def PrepareTransitions():
  # STEP 1: randomly assign transitions where the user didn't specify them
  cnt=sum([1 for page in xrange(1,PageCount+1) if GetPageProp(page,'transition') is None])
  newtrans=((cnt/len(AvailableTransitions)+1)*AvailableTransitions)[:cnt]
  random.shuffle(newtrans)
  for page in xrange(1,PageCount+1):
    if GetPageProp(page,'transition') is None:
      SetPageProp(page,'transition',newtrans.pop())
      SetPageProp(page,'IsRandomTransition',True)

  # STEP 2: instantiate transitions
  for page in PageProps:
    PageProps[page]['transition']=PageProps[page]['transition']()


##### OVERVIEW MODE ############################################################

# draw the overview page
def DrawOverview():
  glDisable(GL_BLEND)
  glBindTexture(GL_TEXTURE_2D,Tnext)
  glColor3ub(192,192,192)
  DrawFullQuad()

  pos=OverviewPos(Pnext)
  X0=PixelX* pos[0]
  Y0=PixelY* pos[1]
  X1=PixelX*(pos[0]+OverviewCellX)
  Y1=PixelY*(pos[1]+OverviewCellY)
  glColor3d(1,1,1)
  glBegin(GL_QUADS)
  DrawPoint(X0,Y0)
  DrawPoint(X1,Y0)
  DrawPoint(X1,Y1)
  DrawPoint(X0,Y1)
  glEnd()

  pygame.display.flip()

# overview zoom effect, time mapped through func
def OverviewZoom(func):
  pos=OverviewPos(Pcurrent)
  X0=PixelX*(pos[0]+OverviewBorder)
  Y0=PixelY*(pos[1]+OverviewBorder)
  X1=PixelX*(pos[0]-OverviewBorder+OverviewCellX)
  Y1=PixelY*(pos[1]-OverviewBorder+OverviewCellY)

  t0=pygame.time.get_ticks()
  while 1:
    t=(pygame.time.get_ticks()-t0)*1.0/ZoomDuration
    if t>=1.0: break
    t=func(t)
    t1=t*t
    t=1.0-t1

    zoom=(t*(X1-X0)+t1)/(X1-X0)
    OX=zoom*(t*X0-X0)-(zoom-1.0)*t*X0
    OY=zoom*(t*Y0-Y0)-(zoom-1.0)*t*Y0
    OX=t*X0-zoom*X0
    OY=t*Y0-zoom*Y0

    glDisable(GL_BLEND)
    glBindTexture(GL_TEXTURE_2D,Tnext)
    glBegin(GL_QUADS)
    glColor3ub(192,192,192)
    glTexCoord(    0.0,    0.0); glVertex2d(OX,     OY)
    glTexCoord(TexMaxS,    0.0); glVertex2d(OX+zoom,OY)
    glTexCoord(TexMaxS,TexMaxT); glVertex2d(OX+zoom,OY+zoom)
    glTexCoord(    0.0,TexMaxT); glVertex2d(OX,     OY+zoom)
    glColor3d(1,1,1)
    glTexCoord(X0*TexMaxS,Y0*TexMaxT); glVertex2d(OX+X0*zoom,OY+Y0*zoom)
    glTexCoord(X1*TexMaxS,Y0*TexMaxT); glVertex2d(OX+X1*zoom,OY+Y0*zoom)
    glTexCoord(X1*TexMaxS,Y1*TexMaxT); glVertex2d(OX+X1*zoom,OY+Y1*zoom)
    glTexCoord(X0*TexMaxS,Y1*TexMaxT); glVertex2d(OX+X0*zoom,OY+Y1*zoom)
    glEnd()

    EnableAlphaBlend()
    glBindTexture(GL_TEXTURE_2D,Tcurrent)
    glColor4d(1,1,1,1.0-t*t*t)
    glBegin(GL_QUADS)
    glTexCoord(    0.0,    0.0); glVertex2d(t*X0,   t*Y0)
    glTexCoord(TexMaxS,    0.0); glVertex2d(t*X1+t1,t*Y0)
    glTexCoord(TexMaxS,TexMaxT); glVertex2d(t*X1+t1,t*Y1+t1)
    glTexCoord(    0.0,TexMaxT); glVertex2d(t*X0,   t*Y1+t1)
    glEnd()
    pygame.display.flip()

# overview keyboard navigation
def OverviewKeyboardNav(delta):
  global Pnext
  dest=Pnext+delta
  if dest>PageCount or dest<1: return
  Pnext=dest
  x,y=OverviewPos(Pnext)
  pygame.mouse.set_pos((x+(OverviewCellX/2),y+(OverviewCellY/2)))

# overview event handler
def HandleOverviewEvent(event):
  global Pcurrent,Pnext

  if event.type==QUIT:
    Quit()
  elif event.type==VIDEOEXPOSE:
    DrawOverview()

  elif event.type==KEYDOWN:
    if event.key in (K_ESCAPE,ord("q")):
      pygame.event.post(pygame.event.Event(QUIT))
    elif event.key==ord("f"):
      SetFullscreen(not Fullscreen)
    elif event.key==ord("s"):
      SaveInfoScript(FileName+".info")
    elif event.key==K_UP:     OverviewKeyboardNav(-OverviewGridSize)
    elif event.key==K_LEFT:   OverviewKeyboardNav(-1)
    elif event.key==K_RIGHT:  OverviewKeyboardNav(+1)
    elif event.key==K_DOWN:   OverviewKeyboardNav(+OverviewGridSize)
    elif event.key==K_TAB:
      Pnext=Pcurrent
      return 0
    elif event.key in (K_RETURN,K_KP_ENTER):
      return 0

  elif event.type==MOUSEBUTTONUP:
    if event.button==1:
      return 0
    elif event.button==3:
      Pnext=Pcurrent
      return 0

  elif event.type==MOUSEMOTION:
    pygame.event.clear(MOUSEMOTION)
    # mouse move in fullscreen mode -> show mouse cursor and reset mouse timer
    if Fullscreen:
      pygame.time.set_timer(USEREVENT+0,MouseHideDelay)
      pygame.mouse.set_visible(True)
    # determine highlighted page
    Pnext=int((event.pos[0]-OverviewOfsX)/OverviewCellX)+1 \
         +int((event.pos[1]-OverviewOfsY)/OverviewCellY)*OverviewGridSize
    DrawOverview()

  elif event.type==USEREVENT+0:
    # mouse timer event -> hide fullscreen cursor
    pygame.time.set_timer(USEREVENT+0,0)
    pygame.mouse.set_visible(False)
  return 1

# overview mode entry/loop/exit function
def DoOverview():
  global Pcurrent,Pnext,Tcurrent,Tnext,Tracing

  pygame.time.set_timer(USEREVENT+1,0)

  glBindTexture(GL_TEXTURE_2D,Tnext)
  glTexImage2D(GL_TEXTURE_2D,0,3,TexWidth,TexHeight,0,GL_RGB,GL_UNSIGNED_BYTE,OverviewImage.tostring())

  if GetPageProp(Pcurrent,'boxes') or Tracing:
    BoxFade(lambda t: 1.0-t)
  Tracing=False
  Pnext=Pcurrent

  OverviewZoom(lambda t: 1.0-t)
  DrawOverview()
  while HandleOverviewEvent(pygame.event.wait()): pass

  if Pnext>PageCount or Pnext<1:
    Pnext=Pcurrent
  if Pnext!=Pcurrent:
    Pcurrent=Pnext
    RenderPage(Pcurrent,Tcurrent)
  OverviewZoom(lambda t: t)
  DrawCurrentPage()

  if GetPageProp(Pcurrent,'boxes'):
    BoxFade(lambda t: t)
  PageEntered()
  if not PreloadNextPage(Pcurrent+1): PreloadNextPage(Pcurrent-1)


##### EVENT HANDLING ###########################################################

# set fullscreen mode
def SetFullscreen(fs,do_init=True):
  global Fullscreen

  # let pygame do the real work
  if do_init:
    if fs==Fullscreen: return
    if not pygame.display.toggle_fullscreen(): return
  Fullscreen=fs

  # redraw the current page (pygame is too lazy to send an expose event ...)
  DrawCurrentPage()

  # show cursor and set auto-hide timer
  if fs:
    pygame.time.set_timer(USEREVENT+0,MouseHideDelay)
  else:
    pygame.time.set_timer(USEREVENT+0,0)
    pygame.mouse.set_visible(True)

# main event handling function
def HandleEvent(event):
  global HaveMark,ZoomMode,Marking,Tracing,Panning,SpotRadius
  global MarkUL,MarkLR,MouseDownX,MouseDownY,PanAnchorX,PanAnchorY,ZoomX0,ZoomY0

  if event.type==QUIT:
    Quit()
  elif event.type==VIDEOEXPOSE:
    DrawCurrentPage()

  elif event.type==KEYDOWN:
    if event.key in (K_ESCAPE,ord("q")):
      pygame.event.post(pygame.event.Event(QUIT))
    elif event.key==ord("f"):
      SetFullscreen(not Fullscreen)
    elif event.key==ord("s"):
      SaveInfoScript(FileName+".info")
    elif event.key in (ord("z"),ord("y")):  # handle QWERTY and QWERTZ keyboards
      if ZoomMode:
        LeaveZoomMode()
      else:
        tx,ty=MouseToScreen(pygame.mouse.get_pos())
        EnterZoomMode(0.5*tx,0.5*ty)
    elif event.key==K_TAB:
      LeaveZoomMode()
      DoOverview()
    elif event.key in (32,K_DOWN,K_RIGHT,K_PAGEDOWN):
      LeaveZoomMode()
      TransitionTo(Pcurrent+1)
    elif event.key in (K_BACKSPACE,K_UP,K_LEFT,K_PAGEUP):
      LeaveZoomMode()
      TransitionTo(Pcurrent-1)
    elif event.key in (K_RETURN,K_KP_ENTER):
      if not(GetPageProp(Pcurrent,'boxes')) and Tracing:
        BoxFade(lambda t: 1.0-t)
      Tracing=not(Tracing)
      if not(GetPageProp(Pcurrent,'boxes')) and Tracing:
        BoxFade(lambda t: t)
    elif event.key in (K_PLUS,K_KP_PLUS):
      SpotRadius+=8
      GenerateSpotMesh()
      if Tracing: DrawCurrentPage()
    elif event.key in (K_MINUS,K_KP_MINUS):
      if SpotRadius>8:
        SpotRadius-=8
        GenerateSpotMesh()
        if Tracing: DrawCurrentPage()

  elif event.type==MOUSEBUTTONDOWN:
    MouseDownX,MouseDownY=event.pos
    if event.button==1:
      MarkUL=MarkLR=MouseToScreen(event.pos)
    if event.button==3 and ZoomMode:
      PanAnchorX=ZoomX0
      PanAnchorY=ZoomY0

  elif event.type==MOUSEBUTTONUP:
    if event.button==1:
      if Marking:
        # left mouse button released in marking mode -> stop box marking
        Marking=False
        # reject too small boxes
        if abs(MarkUL[0]-MarkLR[0])>0.04 and abs(MarkUL[1]-MarkLR[1])>0.03:
          boxes=GetPageProp(Pcurrent,'boxes',[])
          oldboxcount=len(boxes)
          boxes.append(NormalizeRect(MarkUL[0],MarkUL[1],MarkLR[0],MarkLR[1]))
          SetPageProp(Pcurrent,'boxes',boxes)
          if not(oldboxcount) and not(Tracing):
            BoxFade(lambda t: t)
        DrawCurrentPage()
      else:
        # left mouse button released, but no marking -> proceed to next page
        LeaveZoomMode()
        TransitionTo(Pcurrent+1)
    if event.button==3 and not(Panning):
      # right mouse button -> check if a box has to be killed
      boxes=GetPageProp(Pcurrent,'boxes',[])
      x,y=MouseToScreen(event.pos)
      try:
        # if a box is already present around the clicked position, kill it
        idx=FindBox(x,y,boxes)
        if len(boxes)==1 and not(Tracing):
          BoxFade(lambda t: 1.0-t)
        del boxes[idx]
        SetPageProp(Pcurrent,'boxes',boxes)
        DrawCurrentPage()
      except ValueError:
        # no box present -> go to previous page
        LeaveZoomMode()
	TransitionTo(Pcurrent-1)
    Panning=False

  elif event.type==MOUSEMOTION:
    pygame.event.clear(MOUSEMOTION)
    # mouse move in fullscreen mode -> show mouse cursor and reset mouse timer
    if Fullscreen:
      pygame.time.set_timer(USEREVENT+0,MouseHideDelay)
      pygame.mouse.set_visible(True)
    # activate marking if mouse is moved away far enough
    if event.buttons[0] and not(Marking):
      x,y=event.pos
      if abs(x-MouseDownX)>4 and abs(y-MouseDownY)>4:
        Marking=True
    # mouse move while marking -> update marking box
    if Marking:
      MarkLR=MouseToScreen(event.pos)
    # mouse move while RMB is pressed -> panning
    if event.buttons[2] and ZoomMode:
      x,y=event.pos
      if not(Panning) and abs(x-MouseDownX)>4 and abs(y-MouseDownY)>4:
        Panning=True
      ZoomX0=PanAnchorX+(MouseDownX-x)*ZoomArea/ScreenWidth
      ZoomY0=PanAnchorY+(MouseDownY-y)*ZoomArea/ScreenHeight
      ZoomX0=min(max(ZoomX0,0.0),1.0-ZoomArea)
      ZoomY0=min(max(ZoomY0,0.0),1.0-ZoomArea)
    # if anything changed, redraw the page
    if Marking or Tracing or event.buttons[2]:
      DrawCurrentPage()

  elif event.type==USEREVENT+0:
    # mouse timer event -> hide fullscreen cursor
    pygame.time.set_timer(USEREVENT+0,0)
    pygame.mouse.set_visible(False)

  elif event.type==USEREVENT+1:
    TransitionTo(Pcurrent+1)


##### RENDER MODE ##############################################################

def DoRender():
  global TexWidth,TexHeight
  TexWidth=ScreenWidth
  TexHeight=ScreenHeight
  if os.path.exists(RenderToDirectory):
    print "Destination directory `%s' already exists,"%RenderToDirectory
    print "refusing to overwrite anything."
    return 1
  try:
    os.mkdir(RenderToDirectory)
  except OSError, e:
    print "Cannot create destination directory `%s':"%RenderToDirectory
    print e.strerror
    return 1
  print "Rendering presentation into `%s'"%RenderToDirectory
  for page in xrange(1,PageCount+1):
    PageImage(page,RenderMode=True).save("%s/page%04d.png"%(RenderToDirectory,page))
    sys.stdout.write("[%d] "%page)
    sys.stdout.flush()
  print
  print "Done."
  return 0


##### INITIALIZATION ###########################################################

def main():
  global TexWidth,TexHeight,TexMaxS,TexMaxT,MeshStepX,MeshStepY,EdgeX,EdgeY,PixelX,PixelY
  global OverviewGridSize,OverviewCellX,OverviewCellY,OverviewOfsX,OverviewOfsY,OverviewImage
  global PDFinput,Files,PageCount,Resolution,DocumentTitle,PageProps
  global Pcurrent,Pnext,Tcurrent,Tnext

  DocumentTitle=os.path.splitext(os.path.split(FileName)[1])[0]
  PageCount=0

  # try to get a list of image files
  PDFinput=False
  try:
    Files=filter(lambda name: os.path.splitext(name)[1].lower() in \
                 (".jpg",".jpeg",".png",".tif",".tiff",".gif",".bmp"), \
          os.listdir(FileName))
    Files.sort()
    PageCount=len(Files)
    for page,file in zip(range(1,PageCount+1),Files):
      SetPageProp(page,'private_title',file)
  except OSError:
    PDFinput=True

  # no image files? try to open the PDF file, then
  if PDFinput:
    # phase 1: internal PDF parser
    try:
      PageCount,pdf_width,pdf_height=analyze_pdf(FileName)
      if Rotation & 1:
        pdf_width,pdf_height=(pdf_height,pdf_width)
      Resolution=min(ScreenWidth*72.0/pdf_width, ScreenHeight*72.0/pdf_height)
    except:
      Resolution=72.0

    # phase 2: use pdftk
    try:
      assert 0==spawn(os.P_WAIT,pdftkPath,["pdftk", \
        FileNameEscape+FileName+FileNameEscape, \
        "dump_data","output",TempFileName])
      pdftkParse(TempFileName)
    except:
      pass

  # no pages? strange ...
  if not PageCount:
    print "Cannot analyze `%s', quitting."%FileName
    sys.exit(1)

  # if rendering is wanted, do it NOW
  if RenderToDirectory:
    sys.exit(DoRender())

  # set up some variables
  TexWidth=npot(ScreenWidth)
  TexHeight=npot(ScreenHeight)
  TexMaxS=ScreenWidth*1.0/TexWidth
  TexMaxT=ScreenHeight*1.0/TexHeight
  MeshStepX=1.0/MeshResX
  MeshStepY=1.0/MeshResY
  PixelX=1.0/ScreenWidth
  PixelY=1.0/ScreenHeight
  EdgeX=BoxEdgeSize*1.0/ScreenWidth
  EdgeY=BoxEdgeSize*1.0/ScreenHeight
  Pcurrent=InitialPage

  # load and execute info script
  try:
    OldPageProps=PageProps
    execfile(FileName+".info",globals())
    NewPageProps=PageProps
    PageProps=OldPageProps
    del OldPageProps
    PageProps.update(NewPageProps)
    del NewPageProps
  except IOError:
    pass
  except:
    print
    print "Oops! The info script is damaged!"
    raise

  # initialize graphics
  pygame.init()
  flags=OPENGL|DOUBLEBUF
  if Fullscreen: flags|=FULLSCREEN
  try:
    pygame.display.set_mode((ScreenWidth,ScreenHeight),flags)
  except:
    print "Oops! Cannot create rendering surface!"
    sys.exit(1)
  pygame.display.set_caption(__title__)
  if Fullscreen:
    pygame.mouse.set_visible(False)
  glOrtho(0.0,1.0, 1.0,0.0, -10.0,10.0)
  glEnable(GL_TEXTURE_2D)

  # prepare logo image
  glBindTexture(GL_TEXTURE_2D,glGenTextures(1))
  glTexImage2D(GL_TEXTURE_2D,0,1,256,64,0,GL_LUMINANCE,GL_UNSIGNED_BYTE,LOGO)
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)

  # initialize overview
  OverviewGridSize=1
  while PageCount>OverviewGridSize*OverviewGridSize: OverviewGridSize+=1
  OverviewCellX=int(ScreenWidth/OverviewGridSize)
  OverviewCellY=int(ScreenHeight/OverviewGridSize)
  OverviewOfsX=int((ScreenWidth-OverviewCellX*OverviewGridSize)/2)
  OverviewOfsY=int((ScreenHeight-OverviewCellY*int((PageCount+OverviewGridSize-1)/OverviewGridSize))/2)
  OverviewImage=Image.new('RGB',(TexWidth,TexHeight))

  # fill overlay "dummy" images
  dummy=Image.new('L',(256,64))
  dummy.fromstring(LOGO)
  maxsize=(OverviewCellX-2*OverviewBorder,OverviewCellY-2*OverviewBorder)
  if dummy.size[0]>maxsize[0] or dummy.size[1]>maxsize[1]:
    dummy.thumbnail(ZoomToFit(dummy.size,maxsize),Image.ANTIALIAS)
  margX=int((OverviewCellX-dummy.size[0])/2)
  margY=int((OverviewCellY-dummy.size[1])/2)
  dummy=dummy.convert(mode='RGB')
  for page in range(1,PageCount+1):
    pos=OverviewPos(page)
    OverviewImage.paste(dummy,(pos[0]+margX,pos[1]+margY))
  del dummy

  # if caching is enabled, pre-render all pages
  if UseCache:
    DrawLogo()
    DrawProgress(0.0)
    pygame.display.flip()

    stop=False
    progress=0.0
    for page in range(InitialPage,PageCount+1)+range(1,InitialPage):
      event=pygame.event.poll()
      while event.type!=NOEVENT:
        if event.type==KEYDOWN:
          if event.key in (K_ESCAPE,ord('q')):
            Quit()
          stop=True
        elif event.type==MOUSEBUTTONUP:
          stop=True
        event=pygame.event.poll()
      if stop: break
      PageImage(page)
      DrawLogo()
      progress+=1.0/PageCount;
      DrawProgress(progress)
      pygame.display.flip()

    # finally, remove the progress bar from the screen
    DrawLogo()
    pygame.display.flip()

  # create buffer textures
  DrawLogo()
  pygame.display.flip()
  Tcurrent,Tnext=glGenTextures(2)
  for T in (Tcurrent,Tnext):
    glBindTexture(GL_TEXTURE_2D,T)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP)
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP)

  # prebuffer current and next page
  Pnext=0
  RenderPage(Pcurrent,Tcurrent)
  PageEntered()
  PreloadNextPage(Pcurrent+1)

  # some other preparations
  PrepareTransitions()
  GenerateSpotMesh()

  # start output and enter main loop
  DrawCurrentPage()
  UpdateCaption(Pcurrent)
  while 1:
    HandleEvent(pygame.event.wait())


##### COMMAND-LINE PARSER AND HELP #############################################

def if_op(cond,res_then,res_else):
  if cond: return res_then
  else:    return res_else

def HelpExit(code=0):
  print """A nice presentation tool.

Usage: """+os.path.basename(sys.argv[0])+""" [OPTION...] <path>

You may either play a PDF file or a directory containing image files.

General options:
  -h,  --help             show this help text
  -f,  --fullscreen       """+if_op(Fullscreen,"do NOT ","")+"""start in fullscreen mode
  -g,  --geometry <WxH>   set window size or fullscreen resolution
       --scale            scale images to fit screen (not used in PDF mode)
       --supersample      use supersampling (only used in PDF mode)
  -s                      --supersample in PDF mode, --scale else
  -r,  --rotate <n>       rotate pages clockwise in 90-degree steps
  -c,  --nocache          disable page image cache (saves a lot of RAM)
  -i,  --initialpage <n>  start with page <n>
  -w,  --wrap             go back to the first page after the last page
  -a,  --auto <seconds>   automatically advance to next page after some seconds
  -t,  --transition <trans[,trans2...]>
                          force a specific transitions or set of transitions
  -l,  --listtrans        print a list of available transitions and exit
  -o,  --output <dir>     don't display the presentation, only render to .png

Timing options:
  -T,  --transtime <ms>   set transition duration in milliseconds
  -D,  --mousedelay <ms>  set mouse hide delay for fullscreen mode (in ms)
  -B,  --boxfade <ms>     set highlight box fade duration in milliseconds
  -Z,  --zoom <ms>        set zoom duration in milliseconds

Expert options:
  -P,  --gspath <path>    set path to GhostScript executable
  -R,  --meshres <XxY>    set mesh resolution for effects (default: 48x36)

For detailed information, visit""",__website__
  sys.exit(code)

def ListTransitions():
  print "Available transitions:"
  trans=[(tc.__name__,tc.__doc__) for tc in AllTransitions]
  trans.sort()
  maxlen=max([len(item[0]) for item in trans])
  for item in trans:
    print "*",item[0].ljust(maxlen),"-",item[1]
  sys.exit(0)

def opterr(msg):
  print "command line parse error:",msg
  print "use `%s -h' to get help"%sys.argv[0]
  print "or visit",__website__,"for full documentation"
  sys.exit(1)

def SetTransitions(list):
  global AvailableTransitions
  TransitionNames=[tc.__name__.lower() for tc in AllTransitions]
  AvailableTransitions=[]
  for trans in list.lower().split(','):
    try:
      AvailableTransitions.append(AllTransitions[TransitionNames.index(trans)])
    except ValueError:
      opterr("unknown transition `%s'"%trans)
      sys.exit(1)

def ParseOptions(argv):
  global FileName,Fullscreen,Scaling,Supersample,GhostScriptPath,UseCache
  global TransitionDuration,MouseHideDelay,BoxFadeDuration,ZoomDuration
  global ScreenWidth,ScreenHeight,MeshResX,MeshResY,InitialPage,Wrap
  global AutoAdvance,RenderToDirectory,Rotation

  try:
    opts,args=getopt.getopt(argv, "hfg:sci:wa:t:lo:r:T:D:B:Z:P:R:", \
    ["help","fullscreen","geometry=","scale","supersample","nocache", \
     "initialpage=","wrap","auto","listtrans","output=","rotate=",
     "transition=","transtime=","mousedelay=","boxfade=","zoom=","gspath=",
     "meshres="])
  except getopt.GetoptError,message:
    opterr(message)

  for opt,arg in opts:
    if opt in ("-h","--help"):
      HelpExit()
    if opt in ("-l","--listtrans"):
      ListTransitions()
    if opt in ("-f","--fullscreen"):
      Fullscreen=not(Fullscreen)
    if opt in ("-s","--scale"):
      Scaling=not(Scaling)
    if opt in ("-s","--supersample"):
      Supersample=2
    if opt in ("-w","--wrap"):
      Wrap=not(Wrap)
    if opt in ("-c","--nocache"):
      UseCache=not(UseCache)
    if opt in ("-t","--transition"):
      SetTransitions(arg)
    if opt in ("-P","--gspath"):
      GhostScriptPath=arg
    if opt in ("-o","--output"):
      RenderToDirectory=arg
    if opt in ("-i","--initialpage"):
      try:
        InitialPage=int(arg)
        assert InitialPage>0
      except:
        opterr("invalid parameter for --initialpage")
    if opt in ("-a","--auto"):
      try:
        AutoAdvance=int(arg)*1000
        assert AutoAdvance>0 and AutoAdvance<=86400000
      except:
        opterr("invalid parameter for --auto")
    if opt in ("-T","--transtime"):
      try:
        TransitionDuration=int(arg)
        assert TransitionDuration>=0 and TransitionDuration<32768
      except:
        opterr("invalid parameter for --transition")
    if opt in ("-D","--mousedelay"):
      try:
        MouseHideDelay=int(arg)
        assert MouseHideDelay>=0 and MouseHideDelay<32768
      except:
        opterr("invalid parameter for --mousedelay")
    if opt in ("-B","--boxfade"):
      try:
        BoxFadeDuration=int(arg)
        assert BoxFadeDuration>=0 and BoxFadeDuration<32768
      except:
        opterr("invalid parameter for --boxfade")
    if opt in ("-Z","--zoom"):
      try:
        ZoomDuration=int(arg)
        assert ZoomDuration>=0 and ZoomDuration<32768
      except:
        opterr("invalid parameter for --zoom")
    if opt in ("-r","--rotate"):
      try:
        Rotation=int(arg)
      except:
        opterr("invalid parameter for --rotate")
      while Rotation < 0: Rotation += 4
      Rotation = Rotation & 3
    if opt in ("-g","--geometry"):
      try:
        ScreenWidth,ScreenHeight=map(int,arg.split("x"))
        assert ScreenWidth>=320 and ScreenWidth<4096
        assert ScreenHeight>=200 and ScreenHeight<4096
      except:
        opterr("invalid parameter for --geometry")
    if opt in ("-R","--meshres"):
      try:
        MeshResX,MeshResY=map(int,arg.split("x"))
        assert MeshResX>0 and MeshResX<=ScreenWidth
        assert MeshResY>0 and MeshResY<=ScreenHeight
      except:
        opterr("invalid parameter for --meshres")

  if len(args)<1:
    opterr("no file to play")
  elif len(args)>1:
    opterr("too much files to play")
  FileName=args[0]


################################################################################

if __name__=="__main__":
  ParseOptions(sys.argv[1:])
  try:
    main()
  except:
    StopSound()
    raise
