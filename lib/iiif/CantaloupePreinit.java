import java.io.StringReader;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.RIOT;
import org.apache.jena.sys.JenaSystem;
import org.apache.jena.vocabulary.RDFS;

/**
 * Initializes Apache Jena on a single thread, then hands off to Cantaloupe.
 *
 * Cantaloupe's Metadata.loadXMP() calls RIOT.init() (line 219) and
 * ModelFactory.createDefaultModel() (line 221) lazily, per request, on Jetty
 * worker threads, whenever it reads orientation from an image's XMP packet.
 * Concurrent first entry can deadlock in the JVM's class initialization: one
 * thread holds NodeFactory's class-init monitor and waits for RDFS's, another
 * holds RDFS's and waits for NodeFactory's. Every later request that touches
 * Jena then blocks forever too, until the Jetty pool is exhausted and the
 * server stops responding. In testing it reproduced within 4 cold starts
 * under concurrent load; with this preinit, 25 of 25 were clean. The same
 * class of bug is tracked upstream as apache/jena#2787.
 *
 * Touching these classes once, before Jetty starts accepting requests, makes
 * the race impossible.
 *
 * Build on the Cantaloupe host, against that host's jar, and rebuild whenever
 * Cantaloupe is upgraded:
 *
 *   javac --release 11 -cp /root/cantaloupe-5.0.6/cantaloupe-5.0.6.jar \
 *     -d /root/preinit /root/CantaloupePreinit.java
 *
 * start.sh launches it with: -cp "$CANT/$JAR:/root/preinit" CantaloupePreinit
 */
public final class CantaloupePreinit {
    public static void main(String[] args) throws Exception {
        long t0 = System.currentTimeMillis();

        JenaSystem.init();
        RIOT.init();

        // Touch the classes seen deadlocked in the thread dumps: ModelCom (via
        // createDefaultModel), NodeFactory (via read/createProperty), RDFS.
        Model m = ModelFactory.createDefaultModel();
        m.read(new StringReader(
                "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"/>"),
                null, "RDF/XML");
        m.createProperty("http://ns.adobe.com/tiff/1.0/", "Orientation");
        RDFS.Resource.getURI();
        m.close();

        System.err.println("[preinit] Jena initialized in "
                + (System.currentTimeMillis() - t0) + " ms");

        edu.illinois.library.cantaloupe.StandaloneEntry.main(args);
    }
}
