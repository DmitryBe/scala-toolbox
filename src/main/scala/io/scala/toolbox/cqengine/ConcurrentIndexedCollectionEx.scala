package io.scala.toolbox.cqengine

import java.util
import com.googlecode.cqengine.ConcurrentIndexedCollection
import com.googlecode.cqengine.attribute.Attribute
import com.googlecode.cqengine.entity.MapEntity
import com.googlecode.cqengine.index.navigable.NavigableIndex
import com.googlecode.cqengine.query.QueryFactory._
import com.googlecode.cqengine.query.parser.sql.SQLParser
import com.googlecode.cqengine.resultset.ResultSet
import scala.collection.JavaConversions._
import scala.collection.mutable

class ConcurrentIndexedCollectionEx(schemaDescription: Map[String, String]) {

  val collection = new ConcurrentIndexedCollection[util.Map[_, _]]
  val attributes = createAttrs(schemaDescription)
  lazy val parser = SQLParser.forPojoWithAttributes(classOf[java.util.Map[_, _]], attributes)

  def addIndexes(indexes: Map[String, String]): ConcurrentIndexedCollectionEx ={

    indexes foreach { idxInfo =>

      val attrName = idxInfo._1
      val idxType = idxInfo._2
      val indexO = attributes.get(attrName) map { attr =>

        val attrType = attr.getAttributeType
        attrType.getTypeName match {
          case "java.lang.String" =>
            val a = attr.asInstanceOf[Attribute[util.Map[_,_], String]]
            createIdxForAttr(idxType, a)
          case "java.lang.Integer" =>
            val a = attr.asInstanceOf[Attribute[util.Map[_,_], java.lang.Integer]]
            createIdxForAttr(idxType, a)
          case "java.lang.Float" =>
            val a = attr.asInstanceOf[Attribute[util.Map[_,_], java.lang.Float]]
            createIdxForAttr(idxType, a)
          case "java.lang.Boolean" =>
            val a = attr.asInstanceOf[Attribute[util.Map[_,_], java.lang.Boolean]]
            createIdxForAttr(idxType, a)
          case x => throw new Exception(s"usupported type: ${x}")
        }
      }
      indexO match {
        case Some(index) =>
          collection.addIndex(index)
        case None =>
      }
    }

    this
  }

  def add(e: MapEntity): Unit ={
    collection.add(e)
  }

  def add(e: java.util.Map[_, _]): Unit ={
    collection.add(new MapEntity(e))
  }

  def query(sql: String): ResultSet[util.Map[_, _]] ={
    parser.retrieve(collection, sql)
  }

  def sumBy(key: String, sql: String): (Float, Int) = {
    val iter = query(sql)
    val result = iter.foldLeft((0f, 0))((pair, row) => {

      row.containsKey(key) match {
        case true =>
          row.get(key) match {
            case v: Int => (pair._1 + v, pair._2 + 1)
            case v: Float => (pair._1 + v, pair._2 + 1)
            case v => throw new Exception(s"unsupported type: ${v.getClass}")
          }
        case false =>
          (pair._1, pair._2 + 1)
      }
    })

    result
  }

  def foldBy(key: String, sql: String, emptyVal: Any = null): mutable.Map[_, Int] ={
    val iter = query(sql)
    val foldedResults = iter.foldLeft(mutable.Map.empty[Any, Int])((map, row) => {

      val mRow = row
      mRow.containsKey(key) match {
        case true =>
          val v = mRow.get(key)
          map(v) = map.getOrElse(v, 0) + 1
        case false =>
          map(emptyVal) = map.getOrElse(emptyVal, 0) + 1
      }
      map
    })

    foldedResults
  }

  def foldBy2(key1: String, key2: String, sql: String, emptyVal: Any = null): mutable.Map[_, Int] ={
    val iter = query(sql)

    val foldedResults = iter.foldLeft(mutable.Map.empty[(Any, Any), Int])((map, row) => {

      val mRow = row
      val hasKey1 = mRow.containsKey(key1)
      val hasKey2 = mRow.containsKey(key2)
      (hasKey1, hasKey2) match {
        case (false, false) =>
          map((emptyVal, emptyVal)) = map.getOrElse((emptyVal, emptyVal), 0) + 1
        case (true, false) =>
          val v1 = mRow.get(key1)
          map((v1, emptyVal)) = map.getOrElse((v1, emptyVal), 0) + 1
        case (false, true) =>
          val v2 = mRow.get(key2)
          map((emptyVal, v2)) = map.getOrElse((emptyVal, v2), 0) + 1
        case (true, true) =>
          val v1 = mRow.get(key1)
          val v2 = mRow.get(key2)
          map((v1, v2)) = map.getOrElse((v1, v2), 0) + 1
      }

      map
    })

    foldedResults
  }

  def count(sql: String): Int = {
    val r = query(sql)
    r.size()
  }

  private def createAttrs(attrs: Map[String, String]): Map[String, Attribute[util.Map[_, _], _]] ={

    val attributes = attrs map {
      case (name, sType) =>
        mapAttribute(name, getAttrsType(sType))
    }
    Map(attributes map {x => x.getAttributeName -> x} toSeq : _*)
  }

  private def getAttrsType(sType: String) = sType match {
    case "java.lang.String" => classOf[java.lang.String]
    case "java.lang.Integer" => classOf[java.lang.Integer]
    case "java.lang.Float" => classOf[java.lang.Float]
    case "java.lang.Boolean" => classOf[java.lang.Boolean]
    case _ => throw new Exception(s"unsupported type: $sType")
  }

  private def createIdxForAttr[A <: Comparable[A]](idxType: String, a: Attribute[util.Map[_, _], A]): NavigableIndex[A, util.Map[_, _]] = {
    idxType match {
      case "NavigableIndex" => NavigableIndex.onAttribute(a)
      case _ => throw new Exception("unsupported index type")
    }
  }

}
