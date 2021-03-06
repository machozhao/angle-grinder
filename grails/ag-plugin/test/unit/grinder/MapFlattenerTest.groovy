package grinder

import org.junit.Test

import java.text.SimpleDateFormat

import static org.junit.Assert.assertEquals

class MapFlattenerTest {

    @Test
    void testParseJsonDate() {
        def mf = new MapFlattener()
        def testMap = [
            customer:[
                id:1,
                name:'bill',
                blah:null
            ],
            keyContact:[
                id:1
            ]
        ]
        def res = mf.flatten(testMap)
        assert res.'customer.id' == "1"
        assert res.'customer.name' == 'bill'
        assert res.'customer.blah' == ''
        assert res.'keyContact.id' == '1'

    }

    @Test
    void testParseListOfInts() {
        def mf = new MapFlattener()
        def testMap = [
                tags: [1, 2]
        ]
        def res = mf.flatten(testMap)
        assert res['tags'] == [1, 2]
        assert res['tags.0'] == '1'
        assert res['tags.1'] == '2'
    }

    @Test
    void testParseListOfMaps() {
        def mf = new MapFlattener()
        def testMap = [
                tags: [[id: 1], [id: 2]]
        ]
        def res = mf.flatten(testMap)
        assert res['tags'] == [[id: 1], [id: 2]]
        assert res['tags.0.id'] == '1'
        assert res['tags.1.id'] == '2'
    }
}
