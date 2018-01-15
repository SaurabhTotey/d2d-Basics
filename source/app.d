import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.random;
import d2d;

/**
 * The actual activity the user will see
 * Determines what the window actually does
 */
class MainScreen : Screen {

    enum width = 100; ///How wide each entity in this demo is
    enum ticksPerSecond = 20; ///How many times the physics should update in a second
    Texture hammerAndSickle; ///The image of the hammer and sickle
    Texture eagle; ///The image of an eagle
    Font textFont; ///The font to render the text
    Sound!(SoundType.Music) ussrAnthem; ///The USSR anthem music
    int wheelDisplacement; ///How much the mouse wheel has been displaced total in the y direction
    iRectangle location; ///Where the image of the hammer and sickle is
    iVector velocity; ///The velocity of the hammer and sickle as components
    int eaglesDestroyed; ///The number of eagles the hammer and sickle destroyed
    iRectangle[] blocks; ///The locations of all of the eagle textures

    /**
     * Deletes all of the eagle locations and starts the hammer and sickle in a new place with a new velocity
     */
    void randomize() {
        this.location = new iRectangle(uniform(0,
                this.container.window.size.x - width), uniform(0,
                this.container.window.size.y - width), width, width);
        int velBound = cast(int)(2 * this.container.window.size.magnitude / width);
        this.velocity = new iVector(uniform(-velBound, velBound), uniform(-velBound, velBound));
        this.eaglesDestroyed = 0;
        this.blocks = null;
    }

    /**
     * Plays the collision or clapping sound
     */
    void playCollisionSound() {
        try {
            new Sound!(SoundType.Chunk)("res/Clap.wav");
        }
        catch (Exception e) {
        }
    }

    /** 
     * Constructs this screen given the container
     * Handles initializing all of the demo components such as textures, music, and logic
     */
    this(Display container) {
        super(container);
        this.hammerAndSickle = new Texture(loadImage("res/HammerAndSickle.png"),
                this.container.window.renderer);
        this.eagle = new Texture(loadImage("res/Eagle.png"), this.container.window.renderer);
        this.textFont = new Font("res/OpenSans-Regular.ttf", width / 3);
        this.randomize();
        this.ussrAnthem = new Sound!(SoundType.Music)("res/USSR-Anthem.mp3");
        musicVolume = MIX_MAX_VOLUME / 4; //Music is a bit loud
    }

    /**
     * Allows the screen to react to incoming events
     * Defines special behaviour for specific events
     */
    void handleEvent(SDL_Event event) {
        //If space is pressed, the hammer and sickle location gets randomized and all of the eagles get deleted
        if (container.keyboard.allKeys[SDLK_SPACE].testAndRelease()) {
            this.randomize();
        }
        //If escape is pressed, the display gets marked to close
        if (container.keyboard.allKeys[SDLK_ESCAPE].testAndRelease()) {
            this.container.isRunning = false;
        }
        //If the left mouse button is clicked, an eagle is placed at the location of the mouse
        if (container.mouse.allButtons[SDL_BUTTON_LEFT].isPressed()) {
            this.blocks ~= new iRectangle(container.mouse.windowLocation.x - width / 2,
                    container.mouse.windowLocation.y - width / 2, width, width);
        }
        //If the right mouse button is clicked, it removes any eagle that is at the mouse location
        if (container.mouse.allButtons[SDL_BUTTON_RIGHT].testAndRelease()) {
            iRectangle[] toRemove = this.blocks.filter!(
                    block => block.contains(container.mouse.windowLocation)).array;
            //toRemove.each!(block => this.blocks = this.blocks.remove(this.blocks.countUntil(block)));
            if (toRemove.length > 0) {
                this.blocks = this.blocks.remove(this.blocks.countUntil(toRemove[$ - 1]));
            }
        }
        //If the mousewheel displacement got changed, it adjusts the music volume based on the change of the mouse wheel
        if (container.mouse.totalWheelDisplacement.y != wheelDisplacement) {
            musicVolume = musicVolume + container.mouse.totalWheelDisplacement.y - wheelDisplacement;
            if (musicVolume < 0)
                musicVolume = 0;
            else if (musicVolume > MIX_MAX_VOLUME)
                musicVolume = MIX_MAX_VOLUME;
            wheelDisplacement = container.mouse.totalWheelDisplacement.y;
        }
    }

    /**
     * What the screen should do every frame update of the application
     * This is essentially called in a while true loop that is limited by FPS
     * Regardless, it handles logic and handles the logic timing separately of the FPS
     */
    override void onFrame() {
        //If the block collides with a wall on either x side, it flips the x-velocity of it
        if (location.x <= 0 || location.x + width >= container.window.size.x) {
            velocity.x *= -1;
            playCollisionSound();
        }
        //If the block collides with a wall on either y side, it flips the y-velocity of it
        if (location.y <= 0 || location.y + width >= container.window.size.y) {
            velocity.y *= -1;
            playCollisionSound();
        }
        //Removes any blocks that are intersecting with the hammer and sickle
        immutable numBlocks = blocks.length;
        blocks = blocks.filter!(block => !location.intersects(block)).array;
        //If any blocks got removed, a collision happened and thus the collision sound gets played and the number of destroyed eagles gets updated
        if (numBlocks > blocks.length) {
            playCollisionSound();
            eaglesDestroyed += numBlocks - blocks.length;
        }
        //Updates the block's location based on it's velocity
        //TODO: There is a better way to do this based on percentage of time until the next tick
        location.x += velocity.x;
        location.y += velocity.y;
    }

    /**
     * Handles actually drawing whatever the screen wants to draw to the screen
     * This screen draws the eagles and then the hammer and sickle
     * Hammer and sickle, as it gets drawn after the eagles, would go on top
     * Text is drawn last so it goes on top of everything; text color changes depending on the amount of eagles destroyed
     */
    override void draw() {
        this.blocks.each!(block => this.container.window.renderer.copy(this.eagle, block));
        this.container.window.renderer.copy(this.hammerAndSickle, this.location);
        this.container.window.renderer.copy(new Texture(this.textFont.renderTextBlended(
                "Eagles Destroyed: " ~ this.eaglesDestroyed.to!string, Color(255,
                (255 - this.eaglesDestroyed < 0) ? 0 : cast(ubyte)(255 - this.eaglesDestroyed),
                (255 - this.eaglesDestroyed < 0) ? 0 : cast(ubyte)(255 - this.eaglesDestroyed))),
                this.container.window.renderer), new iVector(0, 0));
    }

}

/**
 * Entry point for the program
 */
void main() {
    //Creates a display that is initially 640 by 480, resizable, has a magnificent title, and has an icon of Lenin
    Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
            SDL_RENDERER_ACCELERATED, "Saurabh Totey's Testarific Testarooni", "res/Lenin.jpg");
    //Sets the display's screen to the MainScreen that is defined above
    mainDisplay.screen = new MainScreen(mainDisplay);
    //Starts running the display so that it can handle collecting events and limiting framerate and such
    mainDisplay.run();
}
