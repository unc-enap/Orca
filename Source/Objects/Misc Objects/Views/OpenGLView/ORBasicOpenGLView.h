//This code is a small mod of Apple's BasicOpenGLView example code


#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>


typedef struct {
    GLdouble x,y,z;
} recVec;

typedef struct {
	recVec viewPos; // View position
	recVec viewDir; // View direction vector
	recVec viewUp; // View up direction
	recVec rotPoint; // Point to rotate about
	GLdouble aperture; // pContextInfo->camera aperture
	GLint viewWidth, viewHeight; // current window/screen height and width
} recCamera;

@interface ORBasicOpenGLView : NSOpenGLView
{
    IBOutlet id delegate;
	NSMutableDictionary* stanStringAttrib;
	recCamera camera;
	GLfloat worldRotation [4];
	GLfloat objectRotation [4];
	GLfloat shapeSize;
    recVec gOrigin;
}

+ (NSOpenGLPixelFormat*) basicPixelFormat;

- (id) initWithFrame: (NSRect) frameRect;
- (void) awakeFromNib;
- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (void) updateProjection;
- (void) updateModelView;
- (void) resizeGL;
- (void) resetCamera;

- (void)keyDown:(NSEvent*)theEvent;

- (void) mouseDown:(NSEvent*)theEvent;
- (void) rightMouseDown:(NSEvent*)theEvent;
- (void) otherMouseDown:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (void) rightMouseUp:(NSEvent*)theEvent;
- (void) otherMouseUp:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) scrollWheel:(NSEvent*)theEvent;
- (void) rightMouseDragged:(NSEvent*)theEvent;
- (void) otherMouseDragged:(NSEvent*)theEvent;

- (void) drawRect:(NSRect)rect;
- (void) draw3D:(NSRect)rect;

- (void) prepareOpenGL;

- (void) addLighting;
- (void) shinyLighting;
- (void) regularLighting;
@end

