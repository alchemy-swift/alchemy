import Alchemy

struct TestService: Service {
    public typealias Identifier = ServiceIdentifier<TestService>

    struct Config {
        let foo: String
    }

    static var config = Config(foo: "baz")
    static var foo: String = "bar"
    
    let bar: String
    
    static func configure(with config: Config) {
        foo = config.foo
    }
}

extension TestService.Identifier {
    static var foo: Self { "foo" }
}
