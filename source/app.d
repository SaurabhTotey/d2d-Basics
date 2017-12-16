import std.algorithm;
import std.random;
import std.datetime;
import core.thread;
import d2d;

class MainScreen : Screen {

    enum width = 100;
    enum ticksPerSecond = 20;
    Texture hammerAndSickle;
    Texture eagle;
    Sound!(SoundType.Music) ussrAnthem;
    int wheelDisplacement;
    iRectangle location;
    iPoint velocities;
    iRectangle[] blocks;

    void randomize() {
        this.location = new iRectangle(uniform(0,
                this.container.window.size.x - width), uniform(0,
                this.container.window.size.y - width), width, width);
        int velBound = cast(int) (2 * this.container.window.size.magnitude / width);
        this.velocities = new iPoint(uniform(-velBound, velBound), uniform(-velBound, velBound));
        this.blocks = null;
    }

    this(Display container) {
        super(container);
        this.hammerAndSickle = new Texture(loadImage("res/HammerAndSickle.png"),
                this.container.window.renderer);
        this.eagle = new Texture(loadImage("res/Eagle.png"), this.container.window.renderer);
        this.randomize();
        this.ussrAnthem = new Sound!(SoundType.Music)("res/USSR-Anthem.mp3");
        new Thread({
            SysTime lastTickTime;
            while (container.isRunning) {
                if (Clock.currTime() >= lastTickTime + dur!"msecs"((1000 / ticksPerSecond))) {
                    if (location.topLeft.x <= 0
                        || location.topLeft.x + width >= container.window.size.x) {
                        velocities.x *= -1;
                        new Sound!(SoundType.Chunk)("res/Clap.wav");
                    }
                    if (location.topLeft.y <= 0
                        || location.topLeft.y + width >= container.window.size.y) {
                        velocities.y *= -1;
                        new Sound!(SoundType.Chunk)("res/Clap.wav");
                    }
                    location.topLeft.x += velocities.x;
                    location.topLeft.y += velocities.y;
                    lastTickTime = Clock.currTime();
                }
            }
        }).start();
        musicVolume = MIX_MAX_VOLUME / 4;
    }

    override void handleEvent(SDL_Event event) {
        if (container.keyboard.allPressables.filter!(key => key.id == SDLK_SPACE)
                .front.testAndRelease()) {
            this.randomize();
        }
        if (container.mouse.allPressables.filter!(button => button.id == SDL_BUTTON_LEFT)
                .front.testAndRelease()) {
            this.blocks ~= new iRectangle(container.mouse.windowLocation.x - width / 2,
                    container.mouse.windowLocation.y - width / 2, width, width);
        }
        if (container.mouse.totalWheelDisplacement.y != wheelDisplacement) {
            musicVolume = musicVolume + container.mouse.totalWheelDisplacement.y - wheelDisplacement;
            wheelDisplacement = container.mouse.totalWheelDisplacement.y;
        }
    }

    override void onFrame() {

    }

    override void draw() {
        this.container.window.renderer.copy(this.hammerAndSickle, this.location);
        this.blocks.each!(block => this.container.window.renderer.copy(this.eagle, block));
    }

}

void main() {
    Display mainDisplay = new Display(640, 480, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE,
            "Saurabh Totey's Testarific Testarooni", "res/Lenin.jpg");
    mainDisplay.screen = new MainScreen(mainDisplay);
    mainDisplay.run();
}
