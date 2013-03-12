//  This is Jeff LaMarche's GLProgram OpenGL shader wrapper class from his OpenGL ES 2.0 book.
//  A description of this can be found at his page on the topic:
//  http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-ios-chapter-4.html


#import "GLProgram.h"
// START:typedefs
#pragma mark Function Pointer Definitions
typedef void (*GLInfoFunction)(GLuint program, 
                               GLenum pname, 
                               GLint* params);
typedef void (*GLLogFunction) (GLuint program, 
                               GLsizei bufsize, 
                               GLsizei* length, 
                               GLchar* infolog);
// END:typedefs
#pragma mark -
#pragma mark Private Extension Method Declaration
// START:extension
@interface GLProgram()

- (BOOL)compileShader:(GLuint *)shader 
                 type:(GLenum)type 
                 file:(NSString *)file;
- (NSString *)logForOpenGLObject:(GLuint)object 
                    infoCallback:(GLInfoFunction)infoFunc 
                         logFunc:(GLLogFunction)logFunc;
@end
// END:extension
#pragma mark -

@implementation GLProgram
// START:init
- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename 
            fragmentShaderFilename:(NSString *)fShaderFilename
{
    if ((self = [super init])) 
    {
        attributes = [[NSMutableArray alloc] init];
        uniforms = [[NSMutableArray alloc] init];
        NSString *vertShaderPathname, *fragShaderPathname;
        program = glCreateProgram();
        
        vertShaderPathname = [[NSBundle mainBundle] 
                               pathForResource:vShaderFilename 
                                        ofType:@"vsh"];
                
        if (![self compileShader:&vertShader 
                            type:GL_VERTEX_SHADER 
                            file:vertShaderPathname])
            NSLog(@"Failed to compile vertex shader");
        
        // Create and compile fragment shader
        fragShaderPathname = [[NSBundle mainBundle] 
                               pathForResource:fShaderFilename 
                                        ofType:@"fsh"];
        if (![self compileShader:&fragShader 
                            type:GL_FRAGMENT_SHADER 
                            file:fragShaderPathname])
            NSLog(@"Failed to compile fragment shader");
        
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    
    return self;
}
// END:init
// START:compile
- (BOOL)compileShader:(GLuint *)shader 
                 type:(GLenum)type 
                 file:(NSString *)file
{
    GLint status;
    
    NSString *shaderString = [NSString stringWithContentsOfFile:file
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    
    if (shaderString == nil)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    const GLchar *source = (GLchar *)[shaderString UTF8String];
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    [shaderString length];
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

	if (status != GL_TRUE)
	{
		GLint logLength;
		glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
		if (logLength > 0)
		{
			GLchar *log = (GLchar *)malloc(logLength);
			glGetShaderInfoLog(*shader, logLength, &logLength, log);
			NSLog(@"Shader compile log:\n%s", log);
			free(log);
		}
	}	
	
    return status == GL_TRUE;
}
// END:compile
#pragma mark -
// START:addattribute
- (void)addAttribute:(NSString *)attributeName
{
    if (![attributes containsObject:attributeName])
    {
        [attributes addObject:attributeName];
        glBindAttribLocation(program, 
                             [attributes indexOfObject:attributeName], 
                             [attributeName UTF8String]);
    }
}
// END:addattribute
// START:indexmethods
- (GLuint)attributeIndex:(NSString *)attributeName
{
    return [attributes indexOfObject:attributeName];
}
- (GLuint)uniformIndex:(NSString *)uniformName
{
    return glGetUniformLocation(program, [uniformName UTF8String]);
}
// END:indexmethods
#pragma mark -
// START:link
- (BOOL)link
{
    GLint status;
    
    glLinkProgram(program);
    glValidateProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return YES;
}
// END:link
// START:use
- (void)use
{
    glUseProgram(program);
}
// END:use
#pragma mark -
// START:privatelog
- (NSString *)logForOpenGLObject:(GLuint)object 
                    infoCallback:(GLInfoFunction)infoFunc 
                         logFunc:(GLLogFunction)logFunc
{
    GLint logLength = 0, charsWritten = 0;
    
    infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1)
        return nil;
    
    char *logBytes = malloc(logLength);
    logFunc(object, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
                                              length:logLength 
                                            encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}
// END:privatelog
// START:log
- (NSString *)vertexShaderLog
{
    return [self logForOpenGLObject:vertShader 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
    
}
- (NSString *)fragmentShaderLog
{
    return [self logForOpenGLObject:fragShader 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}
- (NSString *)programLog
{
    return [self logForOpenGLObject:program 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                            logFunc:(GLLogFunction)&glGetProgramInfoLog];
}
// END:log

- (void)validate;
{
	GLint logLength;
	
	glValidateProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}	
}

#pragma mark -
// START:dealloc
- (void)dealloc
{
  
    if (vertShader)
        glDeleteShader(vertShader);
        
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (program)
        glDeleteProgram(program);
       
}
// END:dealloc
@end
