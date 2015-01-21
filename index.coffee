# This project is intended to be a script for hubot/grouchy to manage tags during deployment process.
#
# What it does:
# - update room topic with correct tag
# - move tag from staging/queue to prod in room topic during deploy
#
# What it will do someday:
# - warn authors of commits between tags that
# - cut tag on remote for project
#


## Test and temp code only
TEST_TOPIC = 'queue: web-54.1(ong), rosco-12.2(miller), docstor-11.2(andrew) | prod: web-54.0(stephen), rosco-12.1(wyatt) | other stuff | here'
## end test and temp code

# Test it out!
main = () ->
  parsedTopic = new ChatTopic().fromString TEST_TOPIC

  if parsedTopic.toString() != TEST_TOPIC
    throw new Error('something wrong with to string')

  # add tag for new project
  currNumStagingTags = parsedTopic.queueTopic.tags.length
  parsedTopic.addTagToQueue('feeds-12.1', 'tom')
  if parsedTopic.queueTopic.tags.length != currNumStagingTags + 1
    throw new Error('cannot add new tag for non-existing project')

  # add tag for existing project
  currNumStagingTags = parsedTopic.queueTopic.tags.length
  currTopicStr = parsedTopic.toString();
  parsedTopic.addTagToQueue('web-54.2', 'ong')

  if parsedTopic.queueTopic.tags.length != currNumStagingTags
    throw new Error('cannot add new tag for existing project')
  if currTopicStr == parsedTopic.toString
    throw new Error('cannot add new tag for existing project')

  # move all tags to prod
  # move tag for project already in prod
  numQueueTags = parsedTopic.queueTopic.tags.length
  numProdTags = parsedTopic.prodTopic.tags.length
  topicStr = parsedTopic.toString()
  error = new Error('problem moving tag1')
  parsedTopic.moveTagToProd('rosco')

  if parsedTopic.queueTopic.tags.length != numQueueTags - 1
    throw error
  if parsedTopic.prodTopic.tags.length != numProdTags
    throw error
  if parsedTopic.toString() == topicStr
    throw error

  # move tag with no project in prod
  numQueueTags = parsedTopic.queueTopic.tags.length
  numProdTags = parsedTopic.prodTopic.tags.length
  topicStr = parsedTopic.toString()
  error = new Error('problem moving tag2')
  parsedTopic.moveTagToProd('feeds')

  if parsedTopic.queueTopic.tags.length != numQueueTags - 1
    throw error
  if parsedTopic.prodTopic.tags.length != numProdTags + 1
    throw error
  if parsedTopic.toString() == topicStr
    throw error

  # move tag which doesn't exist
  numQueueTags = parsedTopic.queueTopic.tags.length
  numProdTags = parsedTopic.prodTopic.tags.length
  topicStr = parsedTopic.toString()
  error = new Error('problem moving tag3')
  parsedTopic.moveTagToProd('feeds')

  if parsedTopic.queueTopic.tags.length != numQueueTags
    throw error
  if parsedTopic.prodTopic.tags.length != numProdTags
    throw error
  if parsedTopic.toString() != topicStr
    throw error

  # move until queue is empty
  numProdTags = parsedTopic.prodTopic.tags.length
  topicStr = parsedTopic.toString()
  error = new Error('problem moving tag4')

  parsedTopic.moveTagToProd('web')
  parsedTopic.moveTagToProd('docstor')

  if parsedTopic.queueTopic.tags.length != 0
    throw error
  if parsedTopic.prodTopic.tags.length != numProdTags + 1
    throw error
  if parsedTopic.toString() == topicStr
    throw error
  if parsedTopic.queueTopic.toString() != 'queue: ~'
    throw error




class ChatTopic
  toString: () ->
    [@queueTopic.toString(), @prodTopic.toString()].concat(@unparsedSections).join(' | ')

  fromString: (topicStr) ->
    sections = @splitSections_(topicStr)
    @queueTopic = new DeploymentSection().fromString sections.shift()
    @prodTopic = new DeploymentSection().fromString sections.shift()
    @unparsedSections = sections
    return @

  addTagToQueue: (tagName, author) ->
    # TODO get tag from hubot git integration
    # TODO check for monotonic version number?
    tagStr = "#{tagName}(#{author})"
    incomingTag = new ProjectTag().fromString(tagStr)
    @queueTopic.addTag(incomingTag)

  moveTagToProd: (projectName) ->
    # find tag in queue
    queueTags = @queueTopic.tags
    prodTags = @prodTopic.tags

    # if not found exit
    queueMatchIdx = -1
    for tag in queueTags
      queueMatchIdx = queueTags.indexOf(tag) if tag.project == projectName

    if queueMatchIdx < 0
      return false

    incomingProdTag = queueTags.splice(queueMatchIdx, 1)[0]

    # filter prod tag list, save index?
    prodMatchIdx = -1
    for tag in prodTags
      prodMatchIdx = prodTags.indexOf(tag) if tag.project == projectName

    if prodMatchIdx < 0
      prodTags.push incomingProdTag
    else
      prodTags[prodMatchIdx] = incomingProdTag

    return true


  splitSections_: (topicStr) ->
    topicStr.split('|').map (section) -> section.trim()


class DeploymentSection
  constructor: (@env, @tags) ->
    if @tags is undefined
      @tags = []

  toString: () ->
    tagStr = if @tags.length then @tags.map((tag) -> tag.toString()).join(', ') else '~'
    "#{@env}: #{tagStr}"

  fromString: (sectionStr) ->
    [@env, tagsStr] = splitAndTrim sectionStr, ':'
    @tags = splitAndTrim(tagsStr, ',').map (tagStr)->
      return new ProjectTag().fromString(tagStr)

    return @

  addTag: (incomingTag) ->
    @tags = @tags.filter (tag) -> tag.project != incomingTag.project
    @tags.unshift(incomingTag)


class ProjectTag
  constructor: (@author, @project, @versionMajor, @versionMinor) ->

  toString: () ->
    "#{@project}-#{@versionMajor}.#{@versionMinor}(#{@author})"

  fromString: (tagStr) ->
    fragStr = tagStr

    # get project
    [@project, fragStr] = splitOnFirst fragStr, '-'

    # get versions
    [@versionMajor, fragStr] = splitOnFirst fragStr, '\\.'
    [@versionMinor, fragStr] = splitOnFirst fragStr, '\\('

    # finally get author
    @author = fragStr[0..fragStr.length - 2]

    return @


# utils
splitOnFirst = (str, delimiter) ->
  re = new RegExp("#{delimiter}(.+)?")
  str.split(re)

splitAndTrim = (str, delimiter) ->
  return str.split(delimiter).map (x) -> return x.trim()

main()